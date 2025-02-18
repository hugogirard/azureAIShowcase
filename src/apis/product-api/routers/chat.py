from fastapi import APIRouter, Depends
from azure.ai.projects.aio import AIProjectClient
from azure.ai.inference.models import ChatRequestMessage, ChatCompletions
from azure.ai.inference.aio import EmbeddingsClient, ChatCompletionsClient
from azure.search.documents.models import VectorizedQuery
from azure.search.documents.aio import SearchClient
from azure.ai.inference.prompts import PromptTemplate
from ..factory.project_factory import ProjectFactory
import pathlib
from pathlib import Path
import os
from ..utility import get_logger
from opentelemetry import trace

ASSET_PATH = pathlib.Path(__file__).parent.parent.resolve() / "assets"

tracer = trace.get_tracer(__name__)
logger = get_logger(__name__)

router = APIRouter(
    prefix='/api/chat',
    tags=['chat']
)

@router.post('/')
@tracer.start_as_current_span(name="chat_with_products")
async def chat_with_products(project: ProjectFactory = Depends(ProjectFactory)):

    context = {}

    chat = await project.get_chat_completion_client()
    embeddings = await project.get_embedding_client()
    search_client = await project.get_search_client()

    messages = [{"role": "user", "content": "I need a new tent for 4 people, what would you recommend?"}]
    intent = await _get_intent(messages,chat)

    documents = await _get_product_documents(intent,chat,embeddings,search_client,context)
    
    grounded_chat_prompt = PromptTemplate.from_prompty(Path(ASSET_PATH) / "grounded_chat.prompty")
    system_message = grounded_chat_prompt.create_messages(documents=documents, context=context)

    response = await chat.complete(
        model=os.environ["CHAT_MODEL"],
        messages=system_message + messages,
        **grounded_chat_prompt.parameters,
    )
    logger.info(f"💬 Response: {response.choices[0].message}")

    # Return a chat protocol compliant response
    return {"message": response.choices[0].message, "context": context}    

@tracer.start_as_current_span(name="get_intent")
async def _get_intent(messages: list, chat: ChatCompletionsClient) -> str:
    intent_prompty = PromptTemplate.from_prompty(Path(ASSET_PATH) / "intent_mapping.prompty")

    intent_mapping_response: ChatCompletions = await chat.complete(
        model=os.environ["INTENT_MAPPING_MODEL"],
        messages=intent_prompty.create_messages(conversation=messages),
        **intent_prompty.parameters,
    )   

    search_query = intent_mapping_response.choices[0].message.content
    logger.debug(f"🧠 Intent mapping: {search_query}") 

    return search_query

@tracer.start_as_current_span(name="get_product_documents")
async def _get_product_documents(search_query: str, 
                                 chat: ChatCompletionsClient, 
                                 embeddings: EmbeddingsClient, 
                                 search_client: SearchClient,
                                 context: dict):

    top = 5

    embedding = await embeddings.embed(model=os.environ["EMBEDDINGS_MODEL"], input=search_query)
    search_vector = embedding.data[0].embedding
    
    vector_query = VectorizedQuery(vector=search_vector, k_nearest_neighbors=top, fields="contentVector")

    search_results = await search_client.search(
        search_text=search_query, vector_queries=[vector_query], select=["id", "content", "filepath", "title", "url"]
    )

    documents = [
        {
            "id": result["id"],
            "content": result["content"],
            "filepath": result["filepath"],
            "title": result["title"],
            "url": result["url"],
        }
        async for result in search_results
    ]   

    # add results to the provided context
    if "thoughts" not in context:
        context["thoughts"] = []

    # add thoughts and documents to the context object so it can be returned to the caller
    context["thoughts"].append(
        {
            "title": "Generated search query",
            "description": search_query,
        }
    )

    if "grounding_data" not in context:
        context["grounding_data"] = []
    context["grounding_data"].append(documents)

    logger.debug(f"📄 {len(documents)} documents retrieved: {documents}")
    return documents     

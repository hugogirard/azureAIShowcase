from fastapi import APIRouter, Depends
from azure.ai.projects.aio import AIProjectClient
from azure.ai.inference.models import ChatRequestMessage, ChatCompletions
from azure.ai.inference.aio import EmbeddingsClient, ChatCompletionsClient
from azure.ai.inference.prompts import PromptTemplate
from ..factory.project_factory import ProjectFactory
import pathlib
from typing import Annotated
from pathlib import Path
import os
from ..dependencies import get_project
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
    print(ASSET_PATH)
    chat = await project.get_chat_completion_client()
    messages = [{"role": "user", "content": "I need a new tent for 4 people, what would you recommend?"}]
    return await _get_product_documents(messages,chat)
    # embeddings = await project.get_embedding_client()
    # embedding = await embeddings.embed(model=os.environ["EMBEDDINGS_MODEL"], input="This is a nice car")
    # return embedding.data[0].embedding

@tracer.start_as_current_span(name="get_product_documents")
async def _get_product_documents(messages: list, chat: ChatCompletionsClient):

    top = 5
    intent_prompty = PromptTemplate.from_prompty(Path(ASSET_PATH) / "intent_mapping.prompty")

    intent_mapping_response: ChatCompletions = await chat.complete(
        model=os.environ["INTENT_MAPPING_MODEL"],
        messages=intent_prompty.create_messages(conversation=messages),
        **intent_prompty.parameters,
    )   

    search_query = intent_mapping_response.choices[0].message.content
    logger.debug(f"🧠 Intent mapping: {search_query}") 

    return search_query
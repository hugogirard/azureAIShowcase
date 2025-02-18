from dotenv import load_dotenv
import threading
import os
from azure.ai.projects.aio import AIProjectClient
from azure.ai.inference.aio import EmbeddingsClient, ChatCompletionsClient
from azure.ai.projects.models import ConnectionType
from azure.core.credentials import AzureKeyCredential
from azure.search.documents.aio import SearchClient
from azure.identity.aio import DefaultAzureCredential

class ProjectFactory:
    _instance = None
    _lock = threading.Lock()

    def __new__(cls):
        if cls._instance is None:
            with cls._lock:
                if cls._instance is None:
                    cls._instance = super(ProjectFactory, cls).__new__(cls)   
                    cls._instance._initialize_project()

        return cls._instance

    def _initialize_project(self):
        self.project =  AIProjectClient.from_connection_string(
                                conn_str=os.environ["AIPROJECT_CONNECTION_STRING"], 
                                credential=DefaultAzureCredential()
                        )
        self.chat = None
        self.embeddings = None
        self.search_client = None

    def get_project(self) -> AIProjectClient:
        return self.project
    
    async def get_chat_completion_client(self) -> ChatCompletionsClient:
        if self.chat is None:
            self.chat = await self.project.inference.get_chat_completions_client()
        return self.chat
    
    async def get_embedding_client(self) -> EmbeddingsClient:
        if self.embeddings is None:
            self.embeddings = await self.project.inference.get_embeddings_client()
        return self.embeddings

    async def get_search_client(self) -> SearchClient:
        if self.search_client is None:
            search_connection = await self.project.connections.get_default(
                connection_type=ConnectionType.AZURE_AI_SEARCH, include_credentials=True
            )        
            self.search_client = SearchClient(
                index_name=os.environ["AISEARCH_INDEX_NAME"],
                endpoint=search_connection.endpoint_url,
                credential=AzureKeyCredential(key=search_connection.key),
            )    
        return self.search_client  
    
    
    async def dispose(self):
        if self.chat:
            await self.chat.close()
        
        if self.embeddings:
            await self.embeddings.close()

        if self.search_client:
            await self.search_client.close()

        if self.project:            
            await self.project.close()

from dotenv import load_dotenv
import threading
import os
from azure.ai.projects import AIProjectClient
from azure.identity import DefaultAzureCredential

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
        self.project = AIProjectClient.from_connection_string(
                                conn_str=os.environ["AIPROJECT_CONNECTION_STRING"], 
                                credential=DefaultAzureCredential()
                        )

    def get_project(self) -> AIProjectClient:
        return self.project
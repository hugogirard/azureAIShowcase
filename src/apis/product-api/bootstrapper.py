import os
import sys
from logging import Logger
import logging
import pathlib
from fastapi import FastAPI
from .routers import chat
from dotenv import load_dotenv
from azure.monitor.opentelemetry import configure_azure_monitor
from azure.identity import DefaultAzureCredential
from azure.ai.inference.tracing import AIInferenceInstrumentor
from azure.ai.projects import AIProjectClient
from .factory.project_factory import ProjectFactory


class BootStrapper:

    def __init__(self):
        load_dotenv(override=True)
        self.logger = logging.getLogger("app")
        self.logger.setLevel(logging.INFO)
        self.logger.addHandler(logging.StreamHandler(stream=sys.stdout))    
        self.ASSET_PATH = pathlib.Path(__file__).parent.resolve() / "assets"

    def start(self) -> FastAPI:
        AIInferenceInstrumentor().instrument()

        # enable logging message contents
        os.environ["AZURE_TRACING_GEN_AI_CONTENT_RECORDING_ENABLED"] = "true"        
        project = ProjectFactory().get_project()
        tracing_link = f"https://ai.azure.com/tracing?wsid=/subscriptions/{project.scope['subscription_id']}/resourceGroups/{project.scope['resource_group_name']}/providers/Microsoft.MachineLearningServices/workspaces/{project.scope['project_name']}"

        application_insights_connection_string = project.telemetry.get_connection_string()
        if not application_insights_connection_string:
            self.logger.warning(
                "No application insights configured, telemetry will not be logged to project. Add application insights at:"
            )
            self.logger.warning(tracing_link)

            return

        configure_azure_monitor(connection_string=application_insights_connection_string)
        self.logger.info("Enabled telemetry logging to project, view traces at:")
        self.logger.info(tracing_link)      

        # Create the FastAPI instance
        app = FastAPI()

        app.include_router(chat.router)
        
        return app
         

    def get_logger(self,module_name) -> Logger:
        return logging.getLogger(f"app.{module_name}")


         
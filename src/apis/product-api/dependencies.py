from .factory.project_factory import ProjectFactory
from azure.ai.projects.aio import AIProjectClient

async def get_project() -> AIProjectClient:
    return ProjectFactory().get_project()
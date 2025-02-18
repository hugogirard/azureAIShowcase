from fastapi import APIRouter, Depends
from azure.ai.projects.aio import AIProjectClient
from ..dependencies import get_project

router = APIRouter(
    prefix='/api/chat',
    tags=['chat']
)

@router.post('/')
async def index_products(project: AIProjectClient = Depends(get_project)):
    return "hello world"    
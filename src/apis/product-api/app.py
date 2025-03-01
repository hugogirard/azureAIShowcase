from .bootstrapper import BootStrapper
from fastapi.responses import RedirectResponse
from fastapi import FastAPI
from .routers import chat
import asyncio

bootStrapper = BootStrapper()
app = FastAPI()

@app.on_event("shutdown")
async def shutdown_event():
    await bootStrapper.stop()

app.include_router(chat.router)

@app.get('/', include_in_schema=False)
async def root():
    return RedirectResponse(url="/docs")

async def main(): 
    await bootStrapper.start()

if __name__ == "__main__":
    asyncio.run(main())
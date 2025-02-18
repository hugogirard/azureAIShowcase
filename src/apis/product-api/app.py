from .bootstrapper import BootStrapper
from fastapi.responses import RedirectResponse

bootStrapper = BootStrapper()

app = bootStrapper.start()

@app.get('/', include_in_schema=False)
async def root():
    return RedirectResponse(url="/docs")
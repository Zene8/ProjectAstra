from fastapi import APIRouter
from pydantic import BaseModel
import sys
from io import StringIO

router = APIRouter()

class CodeInput(BaseModel):
    code: str

@router.post("/run_code")
async def run_code(code_input: CodeInput):
    old_stdout = sys.stdout
    redirected_output = sys.stdout = StringIO()
    try:
        exec(code_input.code)
        sys.stdout = old_stdout
        return {"output": redirected_output.getvalue()}
    except Exception as e:
        sys.stdout = old_stdout
        return {"output": str(e)}
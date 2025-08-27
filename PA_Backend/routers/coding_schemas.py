from pydantic import BaseModel

class CodeFileBase(BaseModel):
    filename: str
    content: str
    language: str

class CodeFileCreate(CodeFileBase):
    pass

class CodeFile(CodeFileBase):
    id: int
    user_id: int

    class Config:
        orm_mode = True

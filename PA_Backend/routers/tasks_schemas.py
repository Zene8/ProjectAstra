from pydantic import BaseModel

class TaskBase(BaseModel):
    title: str
    is_completed: bool = False

class TaskCreate(TaskBase):
    pass

class Task(TaskBase):
    id: int
    user_id: int

    class Config:
        orm_mode = True

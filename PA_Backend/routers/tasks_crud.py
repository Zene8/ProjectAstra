from sqlmodel import Session, select
from . import models, tasks_schemas

def get_task(db: Session, task_id: int):
    return db.get(models.Task, task_id)

def get_tasks(db: Session, user_id: int, skip: int = 0, limit: int = 100):
    return db.exec(select(models.Task).where(models.Task.user_id == user_id).offset(skip).limit(limit)).all()

def create_task(db: Session, task: tasks_schemas.TaskCreate, user_id: int):
    db_task = models.Task(**task.dict(), user_id=user_id)
    db.add(db_task)
    db.commit()
    db.refresh(db_task)
    return db_task

def update_task(db: Session, task_id: int, task: tasks_schemas.TaskCreate):
    db_task = db.get(models.Task, task_id)
    if not db_task:
        return None
    task_data = task.dict(exclude_unset=True)
    for key, value in task_data.items():
        setattr(db_task, key, value)
    db.add(db_task)
    db.commit()
    db.refresh(db_task)
    return db_task

def delete_task(db: Session, task_id: int):
    task = db.get(models.Task, task_id)
    if not task:
        return None
    db.delete(task)
    db.commit()
    return {"ok": True}
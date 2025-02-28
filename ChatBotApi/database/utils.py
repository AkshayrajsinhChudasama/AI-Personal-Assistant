from firebase_admin import credentials, firestore
import firebase_admin

cred = credentials.Certificate('firebase/firebase-cred.json')
app = firebase_admin.initialize_app(cred)
db = firestore.client()

def get_tasks_collection(db):
    return db.collection('tasks')

def insertTask(email: str, task: dict):
    if not email or not task:
        return {"msg": "Email and task are required", "code": 400}

    task_ref = get_tasks_collection(db).document()
    task['email'] = email
    print(task)
    try:
        task_ref.set(task)
        print(task_ref)
        return {"msg": "Task inserted successfully", "code": 200, "task_id": task_ref.id}
    except Exception as e:
        return {"msg": f"Error inserting task: {str(e)}", "code": 500}

def retriveAllTask(email: str):
    if not email:
        return {"msg": "Email is required", "code": 400}

    tasks_query = get_tasks_collection(db).where("email", "==", email).stream()
    task_list = []
    for task in tasks_query:
        task_data = task.to_dict()
        task_list.append({"id": task.id, **task_data})
    
    if not task_list:
        return {"msg": "No tasks found for this user", "code": 404}
    
    return {"msg": "Tasks retrieved successfully", "code": 200, "data": task_list}

def updateTask(task_id: str, new_task: dict):
    if not task_id or not new_task:
        return {"msg": "Task ID and new task content are required", "code": 400}

    task_ref = get_tasks_collection(db).document(task_id)
    try:
        task_ref.update(new_task)
        return {"msg": "Task updated successfully", "code": 200}
    except Exception as e:
        return {"msg": f"Error updating task: {str(e)}", "code": 500}

def deleteTask(task_id: str):
    if not task_id:
        return {"msg": "Task ID is required", "code": 400}

    task_ref = get_tasks_collection(db).document(task_id)
    try:
        task_ref.delete()
        return {"msg": "Task deleted successfully", "code": 200}
    except Exception as e:
        return {"msg": f"Error deleting task: {str(e)}", "code": 500}

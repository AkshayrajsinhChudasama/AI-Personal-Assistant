from datetime import datetime
from pymongo import MongoClient
from pydantic import BaseModel
from bson import ObjectId
from typing import List, Dict, Any

# Initialize MongoDB client
client = MongoClient('mongodb://localhost:27017/') 
db = client['ChatBot']
tasks_collection = db['Tasks']

async def insertTask(email: str, task: str, event_id: str = None) -> Dict[str, Any]:
    if not email or not task:
        return {"msg": "Email and task are required", "code": 400}
    
    try:
        task_id = event_id if event_id else None

        task_data = {
            "email": email,
            "task": task,
            "task_id": task_id
        }

        result = tasks_collection.insert_one(task_data)
        if(not task_id):
            task_id = str(result.inserted_id)
            tasks_collection.update_one(
                {"_id": result.inserted_id},
                {"$set": {"task_id": task_id}}
            )

        return {
            "msg": "Task inserted successfully",
            "code": 200,
            "task_id": task_id
        }

    except Exception as e:
        return {"msg": f"Error inserting task: {e}", "code": 500}

async def retriveAllTask(email: str) -> Dict[str, Any]:
    if not email:
        return {"msg": "Email is required", "code": 400}
    
    try:
        tasks = tasks_collection.find({"email": email})
    
        task_list = [{"task_id": task["task_id"], "task": task["task"]} for task in tasks]
        
        if not task_list:
            return {"msg": "No tasks found for this user", "code": 404}
        
        return {"msg": "Tasks retrieved successfully", "code": 200, "data": task_list}
    
    except Exception as e:
        return {"msg": f"Error retrieving tasks: {e}", "code": 500}
   

async def updateTask(task_id: str, new_task: str,newid=None) -> Dict[str, Any]:
    if not task_id or not new_task:
        return {"msg": "Task ID and new task content are required", "code": 400}
    
    try:
        if newid:
            result = tasks_collection.update_one(
                {"task_id": task_id},  
                {"$set": {"task": new_task,"task_id":newid}}
            )
        else:
            result = tasks_collection.update_one(
                {"task_id": task_id},  
                {"$set": {"task": new_task}}
            )
        
        if result.matched_count == 0:
            return {"msg": "Task not found", "code": 404}
        return {"msg": "Task updated successfully", "code": 200}
    except Exception as e:
        return {"msg": f"Error updating task: {e}", "code": 500}
    
    
async def deleteTask(task_id: str) -> Dict[str, Any]:
    if not task_id:
        return {"msg": "Task ID is required", "code": 400}
    
    try:
        result = tasks_collection.delete_one({"task_id": task_id})  
        
        if result.deleted_count == 0:
            return {"msg": "Task not found", "code": 404}
        
        return {"msg": "Task deleted successfully", "code": 200}
    
    except Exception as e:
        return {"msg": f"Error deleting task: {e}", "code": 500}
    
messages_collection = db['Messages']

async def insertMessage(email: str, msg: str, by: str) -> Dict[str, Any]:
    if not email or not msg or not by:
        return {"msg": "Email, message, and sender (bot/user) are required", "code": 400}

    if by not in ['bot', 'user']:
        return {"msg": "Sender must be either 'bot' or 'user'", "code": 400}

    try:
        date_time = datetime.now().isoformat()

        message_data = {
            "dateTime": date_time,
            "by": by,
            "msg": msg
        }

        existing_user_messages = messages_collection.find_one({"email": email})

        if existing_user_messages:
            result = messages_collection.update_one(
                {"email": email},
                {"$push": {"messages": message_data}}
            )
        else:
            result = messages_collection.insert_one({
                "email": email,
                "messages": [message_data]
            })

        return {"msg": "Message added successfully", "code": 200}

    except Exception as e:
        return {"msg": f"Error inserting message: {e}", "code": 500}
    
async def retriveMessages(email: str) -> Dict[str, Any]:
    if not email:
        return {"msg": "Email is required", "code": 400}

    try:
        user_messages = messages_collection.find_one({"email": email})

        if not user_messages or not user_messages.get("messages"):
            return {"msg": "No messages found for this user", "code": 404}

        sorted_messages = sorted(user_messages["messages"], key=lambda x: x["dateTime"])

        return {
            "msg": "Messages retrieved successfully",
            "code": 200,
            "data": sorted_messages
        }

    except Exception as e:
        return {"msg": f"Error retrieving messages: {e}", "code": 500}

async def deleteMessages(email: str) -> Dict[str, Any]:
    if not email:
        return {"msg": "Email is required", "code": 400}

    try:
        result = messages_collection.delete_one({"email": email})
        
        if result.deleted_count == 0:
            return {"msg": "No messages found for this user", "code": 404}
        
        return {"msg": "Messages deleted successfully", "code": 200}
    except Exception as e:
        return {"msg": f"Error deleting messages: {e}", "code": 500}
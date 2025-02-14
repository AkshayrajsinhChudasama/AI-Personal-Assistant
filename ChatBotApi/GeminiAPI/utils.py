from datetime import datetime
from dotenv import load_dotenv
import os
import google.generativeai as genai
import json

load_dotenv('./config.env')

GEMINI_KEY = os.getenv("GEMINI_KEY")

genai.configure(api_key=GEMINI_KEY)
model = genai.GenerativeModel("gemini-2.0-flash")

now = datetime.now()
current_date = now.strftime("%Y-%m-%d")  
current_day = now.strftime("%A")  
current_time = now.strftime("%H:%M")

def generalDialog(user_input,chat_history):
  prompt = f"""

     You are a helpful and versatile assistant. You have to answer general knowledge questions, manage user tasks, and handle calendar requests. 
    
    
    - can not do multiple task at a time.
    - based on user query you can do following actions
      - answer any questions user have and try to help according to your knowledge.
      additionally you can
      - add task into the calendar (for this start dateTime and end dateTime required)
      - update specific task
      - delete specific task
    - current tasks of the user is given to you in chat history
    - Some important instruction to follow:
      - in case of adding task
        - if user has provided start date and time then it must be of future not past. (current date and time provided to you).
        - if only start date time provided then ask user for providing end datetime.
        - if user not want to give endtime then take 1 minute by default.
      - in case of updating task
        - if the updated event is added to calendar and update is on timing then updated timing must be in future with respect to current timing.
      - in case of deleting task
        - important -> take confirmation from user that the action can not be undone and specify task that you are going to delete.
    - if user wants to retrive task then give in setence format rather than json format.
    - for performing corrsponding action to database before response sended to user make dbAction = action to be performed and isInfoIncomplete = False.
    - never specify anyting regarding Changes saved to database but notification not allowed. you can allow notification in the app settings. in your response.
    - Context:
      - Today Date and Day: {current_date} ({current_day})
      - Current Time: {current_time}
      - Previous Conversation: {chat_history}
      - User Input: "{user_input}"
    - Your response should be in JSON format with the following structure:
    {{
        "text": "Response text to the user",
        "isInfoIncomplete": true/false,  # true if more information is needed; false if information is enough to perform operation on database
        "dbAction": "add/update/delete/noaction",  # Action to perform in the database
        "calendarAction":"add/update/delete/noaction" # Action to perform in calendar
        decide payload based on dbAction rather than calendarAction.
        "payload": {{
            - for adding task it should have following structure
              "task": "<e.g., 'meeting', 'reminder', 'to-do'>",
              "desc": "Description of the task for Google Calendar (if all information is gathered)",
              "summary": "Summary of the task for Google Calendar (if all information is gathered)",
              --optional fields
              "startdate": "<date in YYYY-MM-DD format if specified>",
              "starttime": "<time in HH:MM format if specified>",
              "enddate": "<date in YYYY-MM-DD format if specified>",
              "endtime": "<time in HH:MM format if specified>",
              "daily":"daily event true / false"
              "other_info": "<other relevant information for the task>"

            - for updating task it should have following structure.
              "_id": id of the task to be updated.
              "updatedPayload":{{
                "full object from dataresult with updated field."
              }}
              e.g  'updatedPayload': ('task_id': 'id of task', 'task': ('task': 'meeting', 'desc': 'meeting with fenil', 'summary': 'meeting with fenil', 'startdate': '2025-01-03', 'starttime': '16:00', 'enddate': '2025-01-03', 'endtime': '19:00', 'other_info': None, 'addedToCalendar': True))
            
            - for deleting task it should have following structure.
              "deletePayload":[list of objects of form Object("_id":"","addedToCalendar":"")] or none
            
        }}  # This section is required if dbAction is other than noaction.
    }}
  """
  eresult = model.generate_content(
            prompt,
            generation_config=genai.GenerationConfig(
                response_mime_type="application/json"
            ),
        )
  extracted_data = json.loads(eresult.text)
  print(extracted_data)
  return extracted_data

def messageGenerator(Task):
  prompt = f"""
    # you are message provide which is creative and beautifull to the given task.
    - give title and body as a output.
    - each time msg title and body should be completly different from given.
    - Context
      - Task : {Task}

    - Output response
    {{
      "title":"should contains title of notification given to user."
      "body":"should contains the body of notification given to user."
    }}
  """
  eresult = model.generate_content(
            prompt,
            generation_config=genai.GenerationConfig(
                response_mime_type="application/json"
            ),
        )
  
  extracted_data = json.loads(eresult.text)
  return extracted_data

def conflictChecker(conflictResult,dataResult,intent):
  prompt = f"""
    # first task : you are conflict checker.

    - you are given with list of task already added and conflict information.
    - give output isConflict = true if result is true else false;
    - in text give message need to output to user. 
    - for given task id in conflict infor find from dataresult and frame beautiful msg without including task id.

    # second task : you are message provide which is creative and beautifull to the given task.
    - give title and body as a output.
    
    # third task : task is given to you and you are going to ask user about the task after 10 minutes
    - give title and body for that.
    - eg. how meeting is going,need any help kind of questoins.

    - Context
      - Conflict information:{conflictResult}
      - dataResult:{dataResult}
      - intent:{intent}

    - Output response
    {{
      
      "isConflict":true/false
      "text":response to user which gives information which tasks are overlapping
      
      # second task
      "title":"should contains title of notification given to user." eg. Time for sweet dreams
      "body":"should contains the body of notification given to user." eg. You got your sleep now please go to bed.

      # third task
      "title1":"title of intereactive msg by bot to the user"
      "body1":"body of intereactive msg by bot to the user"
      eg.
    }}
  """
  eresult = model.generate_content(
            prompt,
            generation_config=genai.GenerationConfig(
                response_mime_type="application/json"
            ),
        )
  
  extracted_data = json.loads(eresult.text)
  print(extracted_data)

  return extracted_data


def conversaction(msg,history):
  prompt = f"""
    # you have a general conversation with user.
    - history and msg of user provided to you 
    - in response give msg which i should give to user.
    - output in 70 word max.
    - Output response
    Context : 
      - message : {msg}
      - history : {history}
    {{
      res:"response need to give to the user.
    }}
  """
  eresult = model.generate_content(
            prompt,
            generation_config=genai.GenerationConfig(
                response_mime_type="application/json"
            ),
        )
  
  extracted_data = json.loads(eresult.text)
  return extracted_data

def check_task_conflict(new_task, existing_tasks):
    print('---------------------------------------------------------------------------------------------------')
    print(new_task, existing_tasks)
    
    new_task_start = datetime.strptime(f"{new_task['startdate']} {new_task['starttime']}", "%Y-%m-%d %H:%M")
    new_task_end = datetime.strptime(f"{new_task['enddate']} {new_task['endtime']}", "%Y-%m-%d %H:%M")
    
    conflicting_tasks = []

    for task in existing_tasks:
        task_start = datetime.strptime(f"{task['task']['startdate']} {task['task']['starttime']}", "%Y-%m-%d %H:%M")
        task_end = datetime.strptime(f"{task['task']['enddate']} {task['task']['endtime']}", "%Y-%m-%d %H:%M")

        if not task['task']['daily']:
            if (new_task_start < task_end and new_task_end > task_start): 
                conflicting_tasks.append(f"Conflict with regular task: {task['task']['task']} (ID: {task['task_id']})")

        if task['task']['daily']:
            task_start_time = datetime.strptime(f"2025-02-14 {task['task']['starttime']}", "%Y-%m-%d %H:%M")
            task_end_time = datetime.strptime(f"2025-02-14 {task['task']['endtime']}", "%Y-%m-%d %H:%M")
            if (new_task_start.time() < task_end_time.time() and new_task_end.time() > task_start_time.time()):
                conflicting_tasks.append(f"Conflict with daily task: {task['task']['task']} (ID: {task['task_id']})")
    
    if conflicting_tasks:
        return {"isConflict": True, "conflicting_tasks": conflicting_tasks}
    else:
        return {"isConflict": False, "message": "No conflict"}


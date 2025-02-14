import json
import requests
from datetime import datetime, timedelta
import pytz

def create_google_calendar_event(access_token, summary, description, start_date, start_time, end_date=None, end_time=None, daily=False):
    try:
        if not access_token:
            print('Failed to get access token')
            return {'success': False, 'message': 'Failed to get access token'}
        
        start_str = f"{start_date}T{start_time}:00"
        start_time_obj = datetime.strptime(start_str, '%Y-%m-%dT%H:%M:%S')
        
        india_tz = pytz.timezone('Asia/Kolkata')
        start_time_obj = india_tz.localize(start_time_obj) if start_time_obj.tzinfo is None else start_time_obj.astimezone(india_tz)
        
        event = {
            'summary': summary,
            'description': description,
            'start': {
                'dateTime': start_time_obj.isoformat(),
                'timeZone': 'Asia/Kolkata',
            },
        }

        if not end_date or not end_time:
            end_time_obj = start_time_obj + timedelta(hours=1)
        else:
            end_str = f"{end_date}T{end_time}:00"
            end_time_obj = datetime.strptime(end_str, '%Y-%m-%dT%H:%M:%S')
            end_time_obj = india_tz.localize(end_time_obj) if end_time_obj.tzinfo is None else end_time_obj.astimezone(india_tz)

        event['end'] = {
            'dateTime': end_time_obj.isoformat(),
            'timeZone': 'Asia/Kolkata',
        }

        if daily:
            event['recurrence'] = ["RRULE:FREQ=DAILY"]

        event['reminders'] = {
            'useDefault': False,
            'overrides': [
                {
                    'method': 'popup',
                    'minutes': 5
                }
            ]
        }

        headers = {
            'Authorization': f'Bearer {access_token}',
            'Content-Type': 'application/json',
        }

        response = requests.post(
            'https://www.googleapis.com/calendar/v3/calendars/primary/events',
            headers=headers,
            data=json.dumps(event),
        )
        
        if response.status_code == 200:
            event_data = response.json()
            print('Event created successfully')
            print(event_data)
            return {
                'success': True,
                'id': event_data.get('id'),
                'summary': event_data.get('summary'),
                'description': event_data.get('description'),
                'start_time': event_data['start']['dateTime'],
                'end_time': event_data.get('end', {}).get('dateTime', None),
            }
        else:
            print(f'Failed to create event: {response.status_code}')
            print(response.text)
            return {
                'success': False,
                'message': f'Failed to create event: {response.status_code}',
                'response': response.text
            }
    except Exception as e:
        print(f'Error creating Google Calendar event: {e}')
        return {
            'success': False,
            'message': f'Error creating event: {e}'
        }
def update_google_calendar_event(access_token, event_id, summary=None, description=None, start_date=None, start_time=None, end_date=None, end_time=None, daily=False):
    try:
        if not access_token:
            print('Failed to get access token')
            return {'success': False, 'message': 'Failed to get access token'}

        india_tz = pytz.timezone('Asia/Kolkata')

        event = {}

        if summary:
            event['summary'] = summary
        if description:
            event['description'] = description

        if start_date and start_time:
            start_str = f"{start_date}T{start_time}:00"
            start_time_obj = datetime.strptime(start_str, '%Y-%m-%dT%H:%M:%S')
            start_time_obj = india_tz.localize(start_time_obj) if start_time_obj.tzinfo is None else start_time_obj.astimezone(india_tz)
            event['start'] = {
                'dateTime': start_time_obj.isoformat(),
                'timeZone': 'Asia/Kolkata',
            }

        if end_date and end_time:
            end_str = f"{end_date}T{end_time}:00"
            end_time_obj = datetime.strptime(end_str, '%Y-%m-%dT%H:%M:%S')
            end_time_obj = india_tz.localize(end_time_obj) if end_time_obj.tzinfo is None else end_time_obj.astimezone(india_tz)
            event['end'] = {
                'dateTime': end_time_obj.isoformat(),
                'timeZone': 'Asia/Kolkata',
            }
        if daily:
            event['recurrence'] = ["RRULE:FREQ=DAILY"]
        else:
            event['recurrence'] = []


        headers = {
            'Authorization': f'Bearer {access_token}',
            'Content-Type': 'application/json',
        }

        response = requests.patch(
            f'https://www.googleapis.com/calendar/v3/calendars/primary/events/{event_id}',
            headers=headers,
            data=json.dumps(event),
        )

        if response.status_code == 200:
            updated_event = response.json()
            print('Event updated successfully')
            print(updated_event)
            return {'success': True, 'updated_event': updated_event}
        else:
            print(f'Failed to update event: {response.status_code}')
            print(response.text)
            return {
                'success': False,
                'message': f'Failed to update event: {response.status_code}',
                'response': response.text
            }
    except Exception as e:
        print(f'Error updating Google Calendar event: {e}')
        return {
            'success': False,
            'message': f'Error updating event: {e}'
        }


def delete_google_calendar_event(access_token, event_id):
    try:
        if not access_token:
            print('Failed to get access token')
            return {'success': False, 'message': 'Failed to get access token'}

        headers = {
            'Authorization': f'Bearer {access_token}',
        }

        response = requests.delete(
            f'https://www.googleapis.com/calendar/v3/calendars/primary/events/{event_id}',
            headers=headers,
        )

        if response.status_code == 204:
            print('Event deleted successfully')
            return {'success': True, 'message': 'Event deleted successfully'}
        else:
            print(f'Failed to delete event: {response.status_code}')
            print(response.text)
            return {
                'success': False,
                'message': f'Failed to delete event: {response.status_code}',
                'response': response.text
            }
    except Exception as e:
        print(f'Error deleting Google Calendar event: {e}')
        return {
            'success': False,
            'message': f'Error deleting event: {e}'
        }

# World Clock API Documentation

## Base URL
- **Local Development**: `http://localhost:5000`
- **Production**: `http://<ingress-ip>/api`

## Endpoints

### 1. Get Time for Specific Timezone

**GET** `/api/time`

Get the current time for a specific timezone.

#### Query Parameters
- `timezone` (optional): IANA timezone string (default: "UTC")

#### Example Request
```bash
curl "http://localhost:5000/api/time?timezone=America/New_York"
```

#### Example Response
```json
{
  "timezone": "America/New_York",
  "datetime": "2025-11-16T03:09:04.717307-05:00",
  "time": "03:09:04",
  "date": "2025-11-16",
  "day": "Sunday",
  "offset": "-0500",
  "offset_hours": -5,
  "is_dst": false
}
```

#### Response Fields
- `timezone`: The requested timezone
- `datetime`: Full ISO 8601 datetime string
- `time`: Time in HH:MM:SS format (24-hour)
- `date`: Date in YYYY-MM-DD format
- `day`: Day of the week
- `offset`: UTC offset in +HHMM or -HHMM format
- `offset_hours`: UTC offset in hours (integer)
- `is_dst`: Whether daylight saving time is active

#### Error Response
```json
{
  "error": "Unknown timezone"
}
```
Status Code: 400

---

### 2. List All Available Timezones

**GET** `/api/timezones`

Get a list of all available IANA timezones grouped by region.

#### Example Request
```bash
curl http://localhost:5000/api/timezones
```

#### Example Response
```json
{
  "count": 594,
  "regions": {
    "Africa": ["Africa/Abidjan", "Africa/Accra", ...],
    "America": ["America/Adak", "America/Anchorage", ...],
    "Asia": ["Asia/Aden", "Asia/Almaty", ...],
    "Europe": ["Europe/Amsterdam", "Europe/Andorra", ...],
    ...
  },
  "common_timezones": [
    "America/New_York",
    "Europe/London",
    "Asia/Tokyo",
    ...
  ]
}
```

#### Response Fields
- `count`: Total number of timezones
- `regions`: Object with timezone arrays grouped by region
- `common_timezones`: Array of commonly used timezones

---

### 3. Get World Clocks for Major Cities

**GET** `/api/world-clocks`

Get current time for multiple major cities simultaneously. This is the primary endpoint used by the frontend dashboard.

#### Example Request
```bash
curl http://localhost:5000/api/world-clocks
```

#### Example Response
```json
{
  "cities": [
    {
      "city": "New York",
      "timezone": "America/New_York",
      "datetime": "2025-11-16T03:09:04.717307-05:00",
      "time": "03:09:04",
      "time_12h": "03:09:04 AM",
      "date": "2025-11-16",
      "day": "Sunday",
      "offset": "-0500",
      "offset_hours": -5,
      "is_day": false,
      "is_dst": false
    },
    {
      "city": "London",
      "timezone": "Europe/London",
      "datetime": "2025-11-16T08:09:04.717829+00:00",
      "time": "08:09:04",
      "time_12h": "08:09:04 AM",
      "date": "2025-11-16",
      "day": "Sunday",
      "offset": "+0000",
      "offset_hours": 0,
      "is_day": true,
      "is_dst": false
    },
    ...
  ],
  "count": 12
}
```

#### Cities Included
- New York (America/New_York)
- London (Europe/London)
- Tokyo (Asia/Tokyo)
- Sydney (Australia/Sydney)
- Dubai (Asia/Dubai)
- Singapore (Asia/Singapore)
- São Paulo (America/Sao_Paulo)
- Mumbai (Asia/Kolkata)
- Paris (Europe/Paris)
- Los Angeles (America/Los_Angeles)
- Hong Kong (Asia/Hong_Kong)
- Berlin (Europe/Berlin)

#### Response Fields (per city)
- `city`: City name
- `timezone`: IANA timezone string
- `datetime`: Full ISO 8601 datetime string
- `time`: Time in HH:MM:SS format (24-hour)
- `time_12h`: Time in 12-hour format with AM/PM
- `date`: Date in YYYY-MM-DD format
- `day`: Day of the week
- `offset`: UTC offset in +HHMM or -HHMM format
- `offset_hours`: UTC offset in hours (integer)
- `is_day`: Boolean indicating if it's daytime (6 AM - 6 PM local time)
- `is_dst`: Whether daylight saving time is active

---

### 4. Health Check

**GET** `/health`

Check if the API is running and healthy.

#### Example Request
```bash
curl http://localhost:5000/health
```

#### Example Response
```json
{
  "status": "healthy"
}
```

---

### 5. Legacy Endpoint

**GET** `/time`

Returns current UTC time. Maintained for backward compatibility.

#### Example Request
```bash
curl http://localhost:5000/time
```

#### Example Response
```json
{
  "current_time": "2025-11-16 08:09:04"
}
```

---

## Error Handling

All endpoints return JSON responses. Errors include:

- **400 Bad Request**: Invalid timezone or parameters
- **500 Internal Server Error**: Server-side error

## CORS

The API has CORS enabled, allowing cross-origin requests from any domain. This is necessary for the frontend to communicate with the backend when running on different ports/domains.

## Rate Limiting

Currently, no rate limiting is implemented. Consider adding rate limiting for production deployments.

## Example Integration

### JavaScript/React
```javascript
const API_URL = 'http://localhost:5000';

// Get world clocks
const response = await fetch(`${API_URL}/api/world-clocks`);
const data = await response.json();
console.log(data.cities);

// Get specific timezone
const response = await fetch(`${API_URL}/api/time?timezone=Asia/Tokyo`);
const data = await response.json();
console.log(data.time);
```

### Python
```python
import requests

# Get world clocks
response = requests.get('http://localhost:5000/api/world-clocks')
data = response.json()
for city in data['cities']:
    print(f"{city['city']}: {city['time']}")

# Get specific timezone
response = requests.get('http://localhost:5000/api/time', 
                       params={'timezone': 'Europe/Paris'})
data = response.json()
print(f"Time in Paris: {data['time']}")
```

### cURL
```bash
# Get world clocks
curl http://localhost:5000/api/world-clocks | jq '.cities[] | {city, time}'

# Get specific timezone
curl "http://localhost:5000/api/time?timezone=Australia/Sydney" | jq .

# Get all timezones
curl http://localhost:5000/api/timezones | jq '.regions.America | .[]' | head -10
```

## Timezone Reference

Common timezone strings to use with the API:

**Americas**
- America/New_York (EST/EDT)
- America/Chicago (CST/CDT)
- America/Denver (MST/MDT)
- America/Los_Angeles (PST/PDT)
- America/Sao_Paulo (BRT/BRST)

**Europe**
- Europe/London (GMT/BST)
- Europe/Paris (CET/CEST)
- Europe/Berlin (CET/CEST)
- Europe/Moscow (MSK)

**Asia**
- Asia/Dubai (GST)
- Asia/Kolkata (IST)
- Asia/Singapore (SGT)
- Asia/Hong_Kong (HKT)
- Asia/Tokyo (JST)

**Oceania**
- Australia/Sydney (AEDT/AEST)
- Pacific/Auckland (NZDT/NZST)

For a complete list, use the `/api/timezones` endpoint.

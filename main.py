import urllib.request
import urllib.parse
import json

def http_request(url, method="GET", data=None, headers=None):
    """
    Hàm chung để thực hiện các yêu cầu HTTP: GET, POST, PUT, DELETE.
    
    Args:
        url (str): URL của yêu cầu.
        method (str): Phương thức HTTP ("GET", "POST", "PUT", "DELETE").
        data (dict, optional): Dữ liệu cho các yêu cầu POST, PUT.
        headers (dict, optional): Các headers của yêu cầu.
    
    Returns:
        str: Phản hồi từ server dưới dạng chuỗi.
    """
    if headers is None:
        headers = {"Content-Type": "application/json"}
    
    if data is not None:
        # Mã hóa dữ liệu thành JSON nếu data không rỗng và định dạng là dict.
        data = json.dumps(data).encode('utf-8')
    
    # Tạo yêu cầu với URL và headers, thêm dữ liệu nếu có.
    req = urllib.request.Request(url, data=data, headers=headers, method=method)
    
    try:
        with urllib.request.urlopen(req) as response:
            return response.read().decode('utf-8')
    except urllib.error.HTTPError as e:
        return f"HTTPError: {e.code} - {e.reason}"
    except urllib.error.URLError as e:
        return f"URLError: {e.reason}"

# Ví dụ sử dụng:
if __name__ == "__main__":
    url = "https://api.cloudflare.com/client/v4"

    # GET Request
    print("GET Response: ")
    print(http_request(url))

    # POST Request
    post_data = {"title": "foo", "body": "bar", "userId": 1}
    print("\nPOST Response: ")
    print(http_request("https://jsonplaceholder.typicode.com/posts", method="POST", data=post_data))

    # PUT Request
    put_data = {"id": 1, "title": "updated title", "body": "new body", "userId": 1}
    print("\nPUT Response: ")
    print(http_request(url, method="PUT", data=put_data))

    # DELETE Request
    print("\nDELETE Response: ")
    print(http_request(url, method="DELETE"))

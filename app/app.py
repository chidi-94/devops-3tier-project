from flask import Flask

app = Flask(__name__)

@app.route("/")
def home():
    return "DevOps 3-Tier Application is running!"

@app.route("/health")
def health():
    return "OK"

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=80)

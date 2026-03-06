import os

from flask import Flask, jsonify

app = Flask(__name__)


@app.route("/")
def root():
    return jsonify(message="Hello from Flask!")


@app.route("/health")
def health():
    return jsonify(status="ok")


if __name__ == "__main__":
    host = os.environ.get("FLASK_RUN_HOST", "0.0.0.0")
    port = int(os.environ.get("FLASK_RUN_PORT", "5000"))
    app.run(host=host, port=port)

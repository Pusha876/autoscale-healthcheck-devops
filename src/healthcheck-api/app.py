from flask import Flask, jsonify
import os

app = Flask(__name__)


@app.route('/health', methods=['GET'])
def health():
    return jsonify({'status': 'healthy'}), 200


@app.route('/crash', methods=['GET'])
def crash():
    os._exit(1)


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)

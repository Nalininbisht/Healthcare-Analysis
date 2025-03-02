import os
from flask import Flask, render_template, request
import pickle
import pandas as pd

# Initialize Flask app
app = Flask(__name__, template_folder="templates")

# Load model safely
try:
    model = pickle.load(open('y_pred_lgb.pkl', 'rb'))
except FileNotFoundError:
    print("Error: 'y_pred_lgb.pkl' not found. Ensure the file exists.")
    exit(1)

@app.route('/', methods=['GET', 'POST'])
def index():
    if request.method == 'GET':
        return render_template('Healthcare.html')  
    else:
        try:
            form_inputs = pd.DataFrame([request.form.to_dict()])
            form_inputs = form_inputs.astype(float)
            prediction = model.predict(form_inputs)
            return f"Predicted Value: {prediction[0]:.2f}"
        except Exception as e:
            return f"Error: {str(e)}"

if __name__ == "__main__":
    app.run(debug=True)

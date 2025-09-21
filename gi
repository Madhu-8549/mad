import streamlit as st
import google.generativeai as genai
import librosa
import numpy as np
from audiorecorder import audiorecorder

# -------------------------------
# Gemini setup
# -------------------------------
genai.configure(api_key="YOUR_GEMINI_API_KEY")

def generate_story_gemini(prompt):
    model = genai.GenerativeModel("gemini-1.5-flash")  # you can use gemini-pro too
    response = model.generate_content(prompt)
    return response.text

# -------------------------------
# Tone detection (simple energy-based)
# -------------------------------
def predict_tone(audio_file_path):
    if not audio_file_path:
        return "neutral"
    y, sr = librosa.load(audio_file_path, sr=16000)
    energy = np.mean(np.abs(y))
    if energy > 0.05:
        return "excited"
    else:
        return "calm"

# -------------------------------
# Streamlit UI
# -------------------------------
def get_user_inputs():
    st.title("📖 Story Generator (Gemini API)")
    char_name = st.text_input("Enter the character's name")
    age = st.number_input("Enter the character's age", min_value=1, max_value=16, step=1)
    char_gender = st.radio("Select the character's gender", options=["Boy", "Girl"])
    genre = st.text_input("Enter the genre")
    setting = st.text_input("Enter the story setting (e.g., Forest, City, Spaceship)")
    moral = st.text_input("Enter the moral of the story")
    return char_name, age, char_gender, genre, setting, moral

def record_audio():
    st.subheader("🎤 Audio Recorder")
    audio = audiorecorder("Click to record", "Click to stop recording")
    audio_file_path = None
    if len(audio) > 0:
        st.audio(audio.export().read())
        audio_file_path = "user_voice.wav"
        audio.export(audio_file_path, format="wav")
    return audio_file_path

# -------------------------------
# Main workflow
# -------------------------------
def main():
    char_name, age, char_gender, genre, setting, moral = get_user_inputs()
    if st.button("Generate Story"):
        # 1. Generate first part
        first_prompt = (
            f"You are a children's book story writer. "
            f"Craft a {genre} story for a {age}-year-old child. "
            f"The story is happening in {setting}. "
            f"The main character is a {age}-year-old {char_gender.lower()} named {char_name}. "
            "Create a sense of anticipation, but do not bring the story to a climax or resolution. "
            "Leave the story open for continuation."
        )
        first_story_part = generate_story_gemini(first_prompt)
        st.subheader("✨ First Part of the Story")
        st.write(first_story_part)

        # 2. Record audio & detect tone
        st.info("Record your voice as you listen to the story 🌝")
        audio_file = record_audio()
        tone = predict_tone(audio_file)
        st.info(f"Detected tone: {tone}")

        # 3. Generate continuation
        continuation_prompt = (
            f"You are a children's book story writer. Continue the story. "
            f"The first part is: {first_story_part}. "
            f"The audience tone is: {tone}. "
            f"The moral of the story should be: {moral}. "
            "Craft a continuation that gradually builds toward the moral."
        )
        with st.spinner("Crafting a personalized story just for you..."):
            second_story_part = generate_story_gemini(continuation_prompt)
            st.subheader("📖 Continuation of the Story")
            st.write(second_story_part)

if _name_ == "_main_":
    main()

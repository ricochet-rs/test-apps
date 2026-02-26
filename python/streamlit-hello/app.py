import streamlit as st

st.set_page_config(page_title="Hello Streamlit", page_icon=":wave:")

st.title("Hello from Streamlit!")
st.write("This is a test Streamlit app deployed on Ricochet.")

name = st.text_input("What's your name?")
if name:
    st.write(f"Hello, {name}!")

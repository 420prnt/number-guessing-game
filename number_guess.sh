#!/bin/bash
PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

# generate actual number
ACTUAL_NUM=$(( RANDOM % 1000 + 1 ))
# set number guesses
NUMBER_OF_GUESSES=0

MAIN_FN(){
  # print asking username
  echo "Enter your username:"
  read USERNAME

  # get user id in db
  USER_ID=$($PSQL "SELECT user_id FROM users WHERE username = '$USERNAME'");

  # check username in db
  if [[ -z $USER_ID ]]
  then
    # print welcome msg for 1st time player
    echo "Welcome, $USERNAME! It looks like this is your first time here."
    # insert new data in db
    INSERT_USER=$($PSQL "INSERT INTO users(username, frequent_games) VALUES('$USERNAME', 0)")
    # get user id in db
    USER_ID=$($PSQL "SELECT user_id FROM users WHERE username = '$USERNAME'");
    FREQUENT_GAMES=0
    BEST_GUESS=0
  else
    USERNAME_DB=$($PSQL "SELECT username FROM users WHERE user_id = $USER_ID");
    FREQUENT_GAMES=$($PSQL "SELECT frequent_games FROM users WHERE user_id = $USER_ID");
    BEST_GUESS=$($PSQL "SELECT MIN(best_guess) FROM games WHERE user_id = $USER_ID");
    
    echo "Welcome back, $USERNAME_DB! You have played $FREQUENT_GAMES games, and your best game took $BEST_GUESS guesses."
  fi

  # run main function
  GAME_FUNCTION
}

GAME_FUNCTION(){
  # Print the initial guess prompt
  echo "Guess the secret number between 1 and 1000:"
  
  while true; do
    read GUESS_NUM
    
    # Increment guess count for every input (valid or invalid)
    ((NUMBER_OF_GUESSES++))
    
    # Validate input
    if ! [[ $GUESS_NUM =~ ^[0-9]+$ ]]
    then
      echo "That is not an integer, guess again:"
    else
      if [[ $GUESS_NUM -eq $ACTUAL_NUM ]]
      then
        # Correct guess
        echo "You guessed it in $NUMBER_OF_GUESSES tries. The secret number was $ACTUAL_NUM. Nice job!"

        # Update user stats
        FREQUENT_GAMES=$((FREQUENT_GAMES + 1))
        UPDATE_RESULTS=$($PSQL "UPDATE users SET frequent_games = $FREQUENT_GAMES WHERE user_id = $USER_ID")

        # Insert game result
        INSERT_GAME=$($PSQL "INSERT INTO games(user_id, best_guess) VALUES($USER_ID, $NUMBER_OF_GUESSES)")
        break
      elif [[ $GUESS_NUM -gt $ACTUAL_NUM ]]
      then
        echo "It's lower than that, guess again:"
      else
        echo "It's higher than that, guess again:"
      fi
    fi
  done
}

# Start the game
MAIN_FN

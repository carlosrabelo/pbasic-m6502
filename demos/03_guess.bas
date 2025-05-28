10 REM Number Guessing Game
20 PRINT "=== Number Guessing Game ==="
30 PRINT "I have chosen a number between 1 and 100."
40 LET T = RND(100)
50 PRINT "Enter your guess: ";
60 INPUT G
70 IF G = T THEN GOTO 130
80 IF G < T THEN PRINT "Too low! Try again."
90 IF G > T THEN PRINT "Too high! Try again."
100 GOTO 50
130 PRINT "Congratulations! You guessed the number!"
140 END

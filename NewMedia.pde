import com.onformative.leap.*;
import com.leapmotion.leap.*;

LeapMotionP5 leap;
PFont keyboardFont;
boolean keyboardButtonPressed = false;

void setup()
{
	size(1200, 600);
    //size(displayWidth, displayHeight);
    //noCursor();

    leap = new LeapMotionP5(this);
    keyboardFont = createFont("HelveticaNeueLight", 48);
}

void draw()
{
    background(0);
    noStroke();

    Keyboard kb = new Keyboard(90);
    kb.display();
    kb.drawOverlayForPosition(mouseX, mouseY);
    
    // if there's a finger on screen
    if(leap.getFingerList().size() > 0)
    {
    	pushMatrix();
    	Finger finger = leap.getFingerList().get(0);
    	PVector position = leap.getTip(finger);
    	translate(position.x, position.y + 100);
    	fill(255);
    	ellipse(0, 0, 10, 10);
    	popMatrix();

    	if(position.z < 100)
    	{
			if(!keyboardButtonPressed)
			{
				// Do action with key
				String key = kb.keyForPositionOnKeyboard((int)position.x, (int)position.y);
				mouseX = (int)position.x;
				mouseY = (int)position.y;
				keyboardButtonPressed = true;
			}
    	}
    	else
    	{
      		keyboardButtonPressed = false;
    	}
    }
}

boolean sketchFullScreen()
{
	return false;
}

class Keyboard
{
	int x, y, buttonSize, fontSize;
	int r = 5;

	String[][] letters = {
		{
			"A", "Z", "E", "R", "T", "Y", "U", "I", "O", "P"
		}
		, {
			"Q", "S", "D", "F", "G", "H", "J", "K", "L", "M"
		}
		, {
			"W", "X", "C", "V", "B", "N", " ", " ", " ", " "
		}
	};

	Keyboard(int buttonSize)
	{
		this.x = (width - letters[0].length * buttonSize) / 2;
		this.y = height - letters.length * buttonSize;
		this.buttonSize = buttonSize;
		this.fontSize = ceil(buttonSize / 2);
	}

	void display()
	{
		int rows = letters.length;
		int columns = letters[0].length;

		int curX, curY;
		textFont(keyboardFont);
		textAlign(CENTER);

		for (int i = 0; i < rows; i++)
		{
			for (int j = 0; j < columns; j++)
			{
				// draw shape
				curX = j * buttonSize + x;
        		curY = i * buttonSize + y;
        		fill(255, 176, 3);
        		stroke(0);
        		strokeWeight(1);

        		if (i == 2 && (j == 6 || j == 8))
        		{
        			fill(#009BFF);
					rect(curX, curY, buttonSize * 2, buttonSize, r, r, r, r);
					fill(255);
					textSize(fontSize - 3);

					if (j == 6)
					{
						text("SPACE", curX, curY + 19, buttonSize * 2, buttonSize);
					}
					else if(j == 8)
					{
						text("BKSP", curX, curY + 19, buttonSize * 2, buttonSize);
					}

					j++;
        		}
		        else
		        {
		        	rect(curX, curY, buttonSize, buttonSize, r, r, r, r);
		        	fill(255);
		        	textSize(fontSize);
		        	text(letters[i][j], curX, curY + 17, buttonSize, buttonSize);
		        }
			}
		}
	}

	void drawOverlayForPosition(int x, int y)
	{
		if (x > this.x + letters[0].length * buttonSize || x < this.x)
			return;

		if (y > this.y + letters.length * buttonSize || y < this.y)
			return;

		for (int i = 0; i < letters.length; i++)
		{
			for (int j = 0; j < letters[0].length; j++)
			{
				if(x >= this.x + j * buttonSize && x <= this.x + (j + 1) * buttonSize && y >= this.y + i * buttonSize && y <= this.y + (i + 1) * buttonSize)
				{
					fill(0, 50);
					noStroke();

					if(i == 2 && j > 7)
					{
						rect(this.x + 8 * buttonSize, this.y + i * buttonSize, buttonSize * 2, buttonSize, r, r, r, r);
					}
					else if (i == 2 && j > 5)
					{
						rect(this.x + 6 * buttonSize, this.y + i * buttonSize, buttonSize * 2, buttonSize, r, r, r, r);
					}
					else
					{
						rect(this.x + j * buttonSize, this.y + i * buttonSize, buttonSize, buttonSize, r, r, r, r);	
					}
				}
			}
		}
	}

	String keyForPositionOnKeyboard(int x, int y)
	{
		if (x > this.x + letters[0].length * buttonSize || x < this.x)
			return null;

		if (y > this.y + letters.length * buttonSize || y < this.y)
			return null;

		for (int i = 0; i < letters.length; i++)
		{
			for (int j = 0; j < letters[0].length; j++)
			{
				if(x >= this.x + j * buttonSize && x <= this.x + (j + 1) * buttonSize && y >= this.y + i * buttonSize && y <= this.y + (i + 1) * buttonSize)
				{
					if(i == 2 && j > 7)
						return "BKSP";

					return letters[i][j];
				}
			}
		}

		return null;
	}	
}
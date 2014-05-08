import com.onformative.leap.*;
import com.leapmotion.leap.*;
import java.util.*;

private static final String INSTAGRAM_CLIENT_ID = "***REMOVED***";
Instagram instagram;
List<MediaFeedData> instagramMediaFeeds;
boolean refreshedInstagramFeed = false;

LeapMotionP5 leap;

Keyboard kb;
PFont keyboardFont;
String keyboardString = "NMCT";
boolean keyboardButtonPressed = false;
boolean userPressedDown = false;

void setup()
{
    size(1200, 600);
    //size(displayWidth, displayHeight);
    //noCursor();

    kb = new Keyboard(90);

    leap = new LeapMotionP5(this);
    keyboardFont = createFont("HelveticaNeueLight", 48);

    instagram = new Instagram(INSTAGRAM_CLIENT_ID);
    refreshInstagramFeed();
}

void draw()
{
    background(0);
    noStroke();

    kb.display();

    if(!kb.hidden && !kb.animating && userPressedDown && keyboardButtonPressed)
        kb.drawOverlayForPosition(mouseX, mouseY);
    
    // if there's a finger on screen
    if(leap.getFingerList().size() > 0)
    {
        pushMatrix();
        int keyboardMouseYOffset = 200;
        Finger finger = leap.getFingerList().get(0);
        PVector position = leap.getTip(finger);
        translate(position.x, position.y + keyboardMouseYOffset);
        fill(255);
        ellipse(0, 0, 15, 15);
        popMatrix();

        if(position.z < 250)
        {
            if(!userPressedDown)
            {
                // check if press on keyboard
                if(!kb.hidden && !kb.animating)
                {
                    String key = kb.keyForPositionOnKeyboard((int)position.x, (int)position.y + keyboardMouseYOffset);
                    if(key != null)
                    {
                        keyboardButtonPressed = true;
                        handleKeyPressed(key);
                        println("key: " + key);
                        mouseX = (int)position.x;
                        mouseY = (int)position.y + keyboardMouseYOffset;

                        kb.drawOverlayForPosition(mouseX, mouseY);
                    }
                }

                if(!kb.animating && kb.hidden)
                    kb.setHidden(!kb.hidden, true);

                userPressedDown = true;
            }
        }
        else
        {
            userPressedDown = false;
            keyboardButtonPressed = false;
        }
    }

    textFont(keyboardFont);
    textSize(50);
    textAlign(CENTER);
    text(keyboardString, 0, 100, width, 60);
}

boolean sketchFullScreen()
{
    return false;
}

/*
    Instagram
*/

void refreshInstagramFeed()
{
    new Thread(new Runnable()
    {
        public void run()
        {
            try
            {
                TagMediaFeed mediaFeed = instagram.getRecentMediaTags(keyboardString);

                instagramMediaFeeds = mediaFeed.getData();
                refreshedInstagramFeed = true;

                for(MediaFeedData data : instagramMediaFeeds)
                {
                    println(data.getImages().getLowResolution().getImageUrl());
                }

                println("Instagrams: " + instagramMediaFeeds.size());
            }
            catch (Exception e)
            {
                println(e.getMessage());

            }
        }
    }).start();
}

/*
    Keyboard
*/

void handleKeyPressed(String key)
{
    if(key == "ENTER")
    {
        refreshInstagramFeed();

        kb.setHidden(true, true);
    }
    else if(key == "BKSP")
    {
        if (keyboardString.length() > 0)
        {
            keyboardString = keyboardString.substring(0, keyboardString.length() - 1);
        }
    }
    else
    {
        keyboardString += key;
    }
}

class Keyboard
{
    int x, y, buttonSize, fontSize;
    int r = 5;

    int currentY;
    boolean hidden = false;
    boolean animating = false;
    float animationDuration = .5;
    int timer;

    String[][] letters = {
        {
            "0", "1", "2", "3", "4", "5", "6", "7", "8", "9"
        },
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

        this.currentY = this.y;
    }

    void display()
    {
        int rows = letters.length;
        int columns = letters[0].length;

        int curX, curY;
        textFont(keyboardFont);
        textAlign(CENTER);

        // animation
        if(this.hidden)
        {
            if(this.animating)
            {
                float offset = (this.timer - millis()) * 0.001 * letters.length * buttonSize / this.animationDuration;
                this.currentY = this.y - (int)offset;

                if(this.currentY >= height)
                {
                    this.currentY = height;
                    this.animating = false;
                }
            }
            else
            {
                this.currentY = height;
            }
        }
        else
        {
            if(this.animating)
            {
                float offset = (this.timer - millis()) * 0.001 * letters.length * buttonSize / this.animationDuration;
                this.currentY = height + (int)offset;

                if(this.currentY <= this.y)
                {
                    this.currentY = this.y;
                    this.animating = false;
                }
            }
            else
            {
                this.currentY = this.y;
            }
        }

        for (int i = 0; i < rows; i++)
        {
            for (int j = 0; j < columns; j++)
            {
                // draw shape
                curX = j * buttonSize + this.x;
                curY = i * buttonSize + this.currentY;
                fill(255, 176, 3);
                stroke(0);
                strokeWeight(1);

                if (i == 3 && (j == 6 || j == 8))
                {
                    fill(#009BFF);
                    rect(curX, curY, buttonSize * 2, buttonSize, r, r, r, r);
                    fill(255);
                    textSize(fontSize - 3);

                    if (j == 6)
                    {
                        text("BKSP", curX, curY + 19, buttonSize * 2, buttonSize);
                    }
                    else if(j == 8)
                    {
                        text("ENTER", curX, curY + 19, buttonSize * 2, buttonSize);
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

                    if(i == 3 && j > 7)
                    {
                        rect(this.x + 8 * buttonSize, this.y + i * buttonSize, buttonSize * 2, buttonSize, r, r, r, r);
                    }
                    else if (i == 3 && j > 5)
                    {
                        rect(this.x + 6 * buttonSize, this.y + i * buttonSize, buttonSize * 2, buttonSize, r, r, r, r);
                    }
                    else
                    {
                        rect(this.x + j * buttonSize, this.y + i * buttonSize, buttonSize, buttonSize, r, r, r, r); 
                    }

                    return;
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
                    if(i == 3 && j > 7)
                        return "ENTER";

                    if(i == 3 && j > 5)
                        return "BKSP";

                    return letters[i][j];
                }
            }
        }

        return null;
    }

    void setHidden(boolean hidden, boolean animated)
    {
        if(hidden != this.hidden)
        {
            kb.timer = millis();
            this.hidden = hidden;
            this.animating = animated;
        }
    }   
}
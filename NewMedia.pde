import com.onformative.leap.*;
import com.leapmotion.leap.*;
import com.leapmotion.leap.Gesture.*;
import java.util.*;
import java.util.concurrent.*;

private static final String INSTAGRAM_CLIENT_ID = "***REMOVED***";
Instagram instagram;
List<MediaFeedData> instagramMediaFeeds = Collections.synchronizedList(new ArrayList<MediaFeedData>());
Map<String, PImage> imageLookupMap = new ConcurrentHashMap<String, PImage>();
boolean refreshedInstagramFeed = false;
int refreshInterval = 10000; // milliseconds
int lastTime;

LeapMotionP5 leap;
int topBarHeight = 44;
PImage clockImage;
PImage placeholderImage;

Keyboard kb;
PFont keyboardFont;
String keyboardString = "NMCT";
boolean keyboardButtonPressed = false;
boolean userPressedDown = false;

boolean sketchFullScreen()
{
    return false;
}

void setup()
{
    size(900, 770);
    //size(displayWidth, displayHeight);
    //if (frame != null) { frame.setResizable(true); }
    //noCursor();

    lastTime = millis();

    clockImage = loadImage("clock.png");
    placeholderImage = loadImage("camera.png");

    kb = new Keyboard(90);

    leap = new LeapMotionP5(this);
    leap.enableGesture(Type.TYPE_SWIPE);
    keyboardFont = createFont("HelveticaNeueLight", 48);

    instagram = new Instagram(INSTAGRAM_CLIENT_ID);
    refreshInstagramFeed();
}

void draw()
{
    try
    {
        background(234, 234, 234);
        noStroke();

        if(kb.hidden && !kb.animating)
            checkTimer();

        drawTopBar();

        synchronized(instagramMediaFeeds)
        {
            if(instagramMediaFeeds.size() > 0)
            {
                int displayMode = 2;

                int i = 0;

                int size = 160;
                int minSpacing = 10;
                int tilesPerRow = floor(width / (size + minSpacing));
                int rows = floor((height - topBarHeight) / (size + minSpacing));
                

                float spacing = 0;
                int rowsfitting = 0;
                float outerSpacing = 0;
                float outerSpacingTop = 0;

                if(displayMode == 1)
                {
                    spacing = (float)(width - tilesPerRow * size) / (float)(tilesPerRow + 1);
                    rowsfitting = floor((height - topBarHeight) / (size + spacing));
                }
                else
                {
                    spacing = 10;
                    outerSpacing = (float)(width - tilesPerRow * size - (tilesPerRow - 1) * spacing) / 2;
                    outerSpacingTop = (float)(height - topBarHeight - rows * size - (rows - 1) * spacing) / 2;
                    rowsfitting = floor((height - topBarHeight) / (size + spacing));
                }

                fill(#fbfbfb);
                strokeWeight(1);
                stroke(#dbdbdb);

                for(MediaFeedData data : instagramMediaFeeds)
                {
                    if(floor((float)i / tilesPerRow) == rowsfitting)
                        break;

                    String id = data.getId();

                    if(displayMode == 1)
                    {
                        rect((i % tilesPerRow + 1) * spacing + (i % tilesPerRow) * size, topBarHeight + (floor((float)i / tilesPerRow) + 1) * spacing + floor((float)i / tilesPerRow) * size, size, size);
                    }
                    else
                    {
                        rect((i % tilesPerRow) * spacing + outerSpacing + (i % tilesPerRow) * size, topBarHeight + (floor((float)i / tilesPerRow)) * spacing + outerSpacingTop + floor((float)i / tilesPerRow) * size, size, size);
                    }

                    if(imageLookupMap.containsKey(id))
                    {
                        PImage img = imageLookupMap.get(id);

                        if(displayMode == 1)
                        {
                            image(img, (i % tilesPerRow + 1) * spacing + (i % tilesPerRow) * size + 5, topBarHeight + (floor((float)i / tilesPerRow) + 1) * spacing + floor((float)i / tilesPerRow) * size + 5, size - 10, size - 10);
                        }
                        else
                        {
                            image(img, (i % tilesPerRow ) * spacing + outerSpacing + (i % tilesPerRow) * size + 5, topBarHeight + (floor((float)i / tilesPerRow)) * spacing + outerSpacingTop + floor((float)i / tilesPerRow) * size + 5, size - 10, size - 10);
                        }
                    }
                    else
                    {
                        // draw placeholder
                        if(displayMode == 1)
                        {
                            image(placeholderImage, (i % tilesPerRow + 1) * spacing + (i % tilesPerRow) * size + (size - 47) / 2, topBarHeight + (floor((float)i / tilesPerRow) + 1) * spacing + floor((float)i / tilesPerRow) * size + (size - 36) / 2, 47, 36);
                        }
                        else
                        {
                            image(placeholderImage, (i % tilesPerRow) * spacing + outerSpacing + (i % tilesPerRow) * size + (size - 47) / 2, topBarHeight + (floor((float)i / tilesPerRow)) * spacing + outerSpacingTop + floor((float)i / tilesPerRow) * size + (size - 36) / 2, 47, 36);
                        }
                    }

                    i++;
                }
            }
            else
            {
                fill(0, 210);
                noStroke();
                rect((width - 300)/2, 90, 300, 80);
                fill(255);
                textFont(keyboardFont);
                textAlign(CENTER);
                textSize(50);
                text("LOADING", 0, 100, width, 60);    
            }
        }

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
            stroke(0);
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

                    userPressedDown = true;
                }
            }
            else
            {
                userPressedDown = false;
                keyboardButtonPressed = false;
            }
        }

        if(!kb.hidden && !kb.animating)
        {
            fill(0, 210);
            noStroke();
            int w = (int)textWidth("#" + keyboardString) + 100;
            rect((width - w)/2, 90, w, 80);
            fill(255);
            textFont(keyboardFont);
            textSize(50);
            text("#" + keyboardString, 0, 100, width, 60);
        }
    }
    catch (Exception e)
    {
        println(e.getMessage());
    }
}

void drawTopBar()
{
    fill(255, 176, 3);
    rect(0, 0, width, topBarHeight);
    fill(255);
    textFont(keyboardFont);
    textSize(24);
    textAlign(LEFT);
    text("#" + keyboardString, 10, 30);
    text(nf(hour(), 2) + ":" + nf(minute(), 2), width - 77, 30);
    image(clockImage, width - 108, 9, 26, 26);
}

void checkTimer()
{
    int passedTime = millis() - lastTime;
    if (passedTime > refreshInterval)
    {
        refreshInstagramFeed();
        lastTime = millis();
    }
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
                List<MediaFeedData> feed = new ArrayList<MediaFeedData>();

                // get first 20
                TagMediaFeed mediaFeed = instagram.getRecentMediaTags(keyboardString);
                feed.addAll(mediaFeed.getData());

                // add second 20
                Pagination pagination = mediaFeed.getPagination();
                feed.addAll(instagram.getRecentMediaNextPage(pagination).getData());

                synchronized(instagramMediaFeeds)
                {
                    instagramMediaFeeds.clear();
                    instagramMediaFeeds.addAll(feed);
                }

                downloadInstagramImages();

                refreshedInstagramFeed = true;
            }
            catch (Exception e)
            {
                println(e.getMessage());
            }
        }
    }).start();
}

void downloadInstagramImages()
{
    ExecutorService pool = Executors.newFixedThreadPool(20);
    int start = millis();
    for(final MediaFeedData data : instagramMediaFeeds)
    {
        String id = data.getId();
        if(!imageLookupMap.containsKey(id))
        {
            pool.execute(new Runnable()
            {
                public void run()
                {
                    String url = data.getImages().getLowResolution().getImageUrl();
                    PImage img = loadImage(url);
                    imageLookupMap.put(data.getId(), img);
                }
            });
        }
    }

    try
    {
        pool.shutdown();
        pool.awaitTermination(2, TimeUnit.MINUTES);
    }
    catch (Exception e)
    {
        println(e.getMessage());
    }
    finally
    {
        println("Finished images download in " + (float)(millis() - start) / 1000.0f + " seconds");
    }
}

/*
    Keyboard
*/

void handleKeyPressed(String key)
{
    if(key == "ENTER")
    {
        refreshInstagramFeed();
        lastTime = millis();

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

public void swipeGestureRecognized(SwipeGesture gesture)
{
    if (gesture.state() == State.STATE_STOP)
    {
        // System.out.println("//////////////////////////////////////");
        // System.out.println("Gesture type: " + gesture.type());
        // System.out.println("ID: " + gesture.id());
        // System.out.println("Position: " + leap.vectorToPVector(gesture.position()));
        // System.out.println("Direction: " + gesture.direction());
        // System.out.println("Duration: " + gesture.durationSeconds() + "s");
        // System.out.println("//////////////////////////////////////");

        if(kb.hidden && !kb.animating && abs(gesture.direction().get(0)) > 0.6)
        {
            println("Swipe detected");
            kb.setHidden(false, true);
        }

        if(gesture.direction().get(0) > 0) // RIGHT
        {

        }
        else // left
        {

        }
    }
}
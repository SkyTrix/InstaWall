import com.onformative.leap.*;
import com.leapmotion.leap.*;
import com.leapmotion.leap.Gesture.*;
import java.util.*;
import java.util.concurrent.*;

private static final String INSTAGRAM_CLIENT_ID = "***REMOVED***";
Instagram instagram;
List<MediaFeedData> instagramMediaFeeds = Collections.synchronizedList(new ArrayList<MediaFeedData>());
Map<String, PImage> imageLookupMap = new ConcurrentHashMap<String, PImage>();
List<ImageRect> imagePositions = new ArrayList<ImageRect>();
boolean refreshedInstagramFeed = false;
int refreshInterval = 10000; // milliseconds
int lastTime = millis();

LeapMotionP5 leap;
int topBarHeight = 44;
PImage clockImage;
PImage placeholderImage;

MediaFeedData detailImageData;
boolean detailMode = false;
int lastGestureTime = millis();

Keyboard kb;
PFont keyboardFont;
String keyboardString = "NMCT";
String hashtag = keyboardString;
boolean keyboardButtonPressed = false;
boolean userPressedDown = false;

boolean sketchFullScreen()
{
    return true;
}

void setup()
{
    //size(900, 770);
    size(displayWidth, displayHeight);
    //if (frame != null) { frame.setResizable(true); }
    //noCursor();

    clockImage = loadImage("clock.png");
    placeholderImage = loadImage("camera.png");

    kb = new Keyboard(90);

    leap = new LeapMotionP5(this);
    leap.enableGesture(Type.TYPE_SWIPE);
    keyboardFont = createFont("HelveticaNeueLight", 48);

    instagram = new Instagram(INSTAGRAM_CLIENT_ID);
    refreshInstagramFeed();
}

void mousePressed()
{
    if(mouseButton == LEFT)
    {
        if(!kb.hidden && !kb.animating)
        {
            String key = kb.keyForPositionOnKeyboard(mouseX, mouseY);
            if(key != null)
            {
                keyboardButtonPressed = true;
                handleKeyPressed(key);

                kb.drawOverlayForPosition(mouseX, mouseY);
            }
        }
        else if(kb.hidden && !kb.animating && !detailMode)
        {
            // find touched picture
            int index = imageIndexForPositionOnScreen(mouseX, mouseY);
            if(index != -1)
            {
                detailMode = true;

                detailImageData = instagramMediaFeeds.get(index);
                String url = detailImageData.getImages().getStandardResolution().getImageUrl();
            }
        }
        else
        {
            detailMode = false;
            detailImageData = null;
        }
    }
    else if(mouseButton == RIGHT)
    {
        if(!detailMode && kb.hidden && !kb.animating)
        {
            keyboardString = hashtag;
            kb.setHidden(false, true);
        }
        else if(!detailMode && !kb.hidden && !kb.animating)
        {
            keyboardString = hashtag;
            kb.setHidden(true, true);
        }
        else if(detailMode && kb.hidden && !kb.animating)
        {
            detailMode = false;
            detailImageData = null;
        }
    }
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

        drawGrid();

        kb.display();

        if(!kb.hidden && !kb.animating && userPressedDown && keyboardButtonPressed)
            kb.drawOverlayForPosition(mouseX, mouseY);
        
        // Show keyboard input when editing
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

        if(detailMode)
        {
            drawOpacity();
            drawDetailView();
        }

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
                    else if(!kb.animating && !detailMode)
                    {
                        // find touched picture
                        int index = imageIndexForPositionOnScreen((int)position.x, (int)position.y + keyboardMouseYOffset);
                        if(index != -1)
                        {
                            detailMode = true;

                            detailImageData = instagramMediaFeeds.get(index);
                            String url = detailImageData.getImages().getStandardResolution().getImageUrl();
                            println("Touched: " + url);
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
    text("#" + hashtag, 10, 30);
    text(nf(hour(), 2) + ":" + nf(minute(), 2), width - 77, 30);
    image(clockImage, width - 108, 9, 26, 26);
}

void drawGrid()
{
    synchronized(instagramMediaFeeds)
    {
        if(instagramMediaFeeds.size() > 0)
        {
            imagePositions.clear();

            int i = 0;

            int size = 160;
            float spacing = 15;
            int tilesPerRow = floor((width - spacing) / (size + spacing));
            int rows = floor((height - topBarHeight - spacing) / (size + spacing));
            float outerSpacing = (float)(width - tilesPerRow * size - (tilesPerRow - 1) * spacing) / 2;
            float outerSpacingTop = (float)(height - topBarHeight - rows * size - (rows - 1) * spacing) / 2;

            fill(#fbfbfb);
            strokeWeight(1);
            stroke(#dbdbdb);

            for(MediaFeedData data : instagramMediaFeeds)
            {
                if(floor((float)i / tilesPerRow) == rows)
                    break;

                String id = data.getId();
                float x, y, w, h;

                x = (i % tilesPerRow) * spacing + outerSpacing + (i % tilesPerRow) * size;
                y = topBarHeight + (floor((float)i / tilesPerRow)) * spacing + outerSpacingTop + floor((float)i / tilesPerRow) * size;
                w = size;
                h = size;

                imagePositions.add(new ImageRect(x, y, w, h));
                rect(x, y, w, h);

                if(imageLookupMap.containsKey(id))
                {
                    PImage img = imageLookupMap.get(id);
                    image(img, x + 5, y + 5, w - 10, h - 10);
                }
                else
                {
                    // draw placeholder
                    image(placeholderImage, x + (size - 47) / 2, y + (size - 36) / 2, 47, 36);
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
}

void drawDetailView()
{
    PImage img = imageLookupMap.get(detailImageData.getId());
    String profileImgUrl = detailImageData.getUser().getProfilePictureUrl();
    PImage profileImg = loadImage(profileImgUrl);
    fill(#fbfbfb);
    strokeWeight(1);
    stroke(0, 0, 0, 127);

    pushMatrix();
    translate((width - 510)/2, (height - 600)/2);
    //rect(0, 0, 510, 600);
    textFont(createFont("Helvetica", 16));

    float stringWidth = textWidth(detailImageData.getCaption().getText());
    int iLines = getCaptionLines(stringWidth);

    rect(0, 0, 510, 560 + (18*iLines));

    image(profileImg, 5, 5, 40, 40);
    image(img, 5, 50, 500, 500);
    fill(63, 115, 151);
    textAlign(LEFT);
    textSize(16);
    text(detailImageData.getUser().getFullName(), 50, 30);
    textSize(14);
    fill(34, 34, 34);
    text(detailImageData.getCaption().getText(), 7, 557, 480, 100); 
    popMatrix();
}

void drawOpacity()
{
    noStroke();
    fill(139, 137, 137, 127);
    rect(0, topBarHeight, width, height);
}

int getCaptionLines(float iWidth)
{
    println("Breedte: "+iWidth);
    int i = 0;
    int iLines = 0;
    i = ceil(iWidth / 525);

    return i;
}

int imageIndexForPositionOnScreen(int x, int y)
{
    int i = 0;

    for(ImageRect rect : imagePositions)
    {
        if(x >= rect.x && x <= rect.x + rect.w && y >= rect.y && y <= rect.y + rect.h)
        {
            return i;
        }

        i++;
    }

    return -1;
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
                TagMediaFeed mediaFeed = instagram.getRecentMediaTags(hashtag);
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
    int start = millis();

    try
    {
        ExecutorService pool = Executors.newFixedThreadPool(20);

        for(final MediaFeedData data : instagramMediaFeeds)
        {
            String id = data.getId();
            if(!imageLookupMap.containsKey(id))
            {
                pool.execute(new Runnable()
                {
                    public void run()
                    {
                        try
                        {
                            String url = data.getImages().getStandardResolution().getImageUrl();
                            println(url);
                            PImage img = loadImage(url);
                            imageLookupMap.put(data.getId(), img);
                        }
                        catch (Exception e)
                        {
                            println(e.getMessage());
                        }
                    }
                });
            }
        }

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
        hashtag = keyboardString;
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

        int passedTime = millis() - lastGestureTime;
        if (passedTime > 2000)
        {
            if(!detailMode && kb.hidden && !kb.animating && abs(gesture.direction().get(0)) > 0.6)
            {
                keyboardString = hashtag;
                kb.setHidden(false, true);
            }
            else if(!detailMode && !kb.hidden && !kb.animating && abs(gesture.direction().get(0)) > 0.6)
            {
                keyboardString = hashtag;
                kb.setHidden(true, true);
            }
            else if(detailMode && kb.hidden && !kb.animating && abs(gesture.direction().get(0)) > 0.6)
            {
                detailMode = false;
                detailImageData = null;
            }

            lastGestureTime = millis();
        }
    }
}
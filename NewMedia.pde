import com.onformative.leap.*;
import com.leapmotion.leap.*;
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
    size(1200, 600);
    //size(displayWidth, displayHeight);
    //noCursor();

    lastTime = millis();

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

    checkTimer();

    synchronized(instagramMediaFeeds)
    {
        int i = 0;
        for(MediaFeedData data : instagramMediaFeeds)
        {
            String id = data.getId();

            if(imageLookupMap.containsKey(id))
            {
                PImage img = imageLookupMap.get(id);
                image(img, (i % 10) * 153, floor((float)i / 10) * 153, 153, 153);
                //println("found key " + id);
            }
            else
            {
                // draw placeholder
            }

            i++;
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

    fill(0, 200);
    noStroke();
    rect((width - 300)/2, 90, 300, 80);
    fill(255);
    textFont(keyboardFont);
    textSize(50);
    textAlign(CENTER);
    text(keyboardString, 0, 100, width, 60);
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
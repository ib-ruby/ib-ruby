
package ibcontroller;

import java.awt.Window;
import javax.swing.JDialog;

class AcceptIncomingConnectionDialogHandler implements WindowHandler {
    public void handleWindow(Window window, int eventID) {
        if (Utils.clickButton(window, "OK")) {
        } else if (Utils.clickButton(window, "Yes")) {
        } else {
            System.err.println("IBController: could not accept incoming connection because we could not find one of the controls.");
        }
    }

    public boolean recogniseWindow(Window window) {
        if (! (window instanceof JDialog)) return false;

        String title = ((JDialog) window).getTitle();
        return (title != null &&
               title.contains("Trader Workstation") &&
               Utils.findLabel(window, "Accept incoming connection") != null);
    }
}


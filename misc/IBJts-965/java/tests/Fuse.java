/*
 * $Id: Fuse.java,v 1.1 2007/12/12 16:35:03 ptitov Exp $
 * 
 * @author Pavel Titov
 * @since Dec 10, 2007
 * 
 * $Log: Fuse.java,v $
 * Revision 1.1  2007/12/12 16:35:03  ptitov
 * int dp2974 api performance
 *
 */
package tests;

/** local instance of the fuse */
public class Fuse extends Thread {
    private long m_ms;
    private Bomb m_bomb;
    
    /** @param name is used for the thread of the Fuse so the thread can be
     *  identified in the call stack and log file entries*/
    public Fuse( String name, long ms, Bomb bomb) {
        super( "Fuse-" + name);
        m_ms = ms;
        m_bomb = bomb;        
    }

    public void run() {
        if( !sleep2( m_ms) ) {
            return;
        }
        
        m_bomb.explode( this);
    }

    public boolean sleep2( long ms) {
        try {
            sleep( ms);
            return true;
        }
        catch( InterruptedException e) {
            interrupt();
            return false;
        }
    }
    
    /** @param name is used for the thread of the Fuse so the thread can be
     *  identified in the call stack and in log file entries*/
    public static Fuse light( String name, long ms, Bomb bomb) {
        Fuse fuse = new Fuse( name, ms, bomb);
        fuse.start();
        return fuse;
    }       

    public static interface Bomb {
        public void explode(Fuse fuse);
    }
}

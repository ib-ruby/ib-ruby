package tests;

import com.ib.client.EClientSocket;

public class Disconnect extends ApiCallback {
	
	public Disconnect() {
		EClientSocket connection = new EClientSocket(this);
		connection.eConnect("dev19", 7496, 0);
		connection.eDisconnect();
	}

	/**
	 * @param args
	 */
	public static void main(String[] args) {
		new Disconnect();
	}

}

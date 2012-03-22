/*
 * AccountDlg.java
 *
 */
package TestJavaClient;

import java.awt.BorderLayout;
import java.awt.Dimension;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.util.Vector;

import javax.swing.BorderFactory;
import javax.swing.JButton;
import javax.swing.JDialog;
import javax.swing.JFrame;
import javax.swing.JLabel;
import javax.swing.JPanel;
import javax.swing.JScrollPane;
import javax.swing.JSplitPane;
import javax.swing.JTable;
import javax.swing.JTextField;
import javax.swing.table.AbstractTableModel;

import com.ib.client.Contract;
import com.ib.client.Util;

public class AccountDlg extends JDialog {
    private JTextField 		m_updateTime = new JTextField();
    private JLabel 			m_timeLabel = new JLabel("Update time:");
    private JButton 		m_close = new JButton( "Close");
    private PortfolioTable 	m_portfolioModel = new PortfolioTable();
    private AcctValueModel 	m_acctValueModel = new AcctValueModel();
    private boolean 		m_rc;
    
    private String m_accountName;
    private boolean m_complete;

    boolean rc()            { return m_rc; }

    public AccountDlg(JFrame parent) {
        super(parent, true);

        JScrollPane acctPane = new JScrollPane(new JTable(m_acctValueModel));
        JScrollPane portPane = new JScrollPane(new JTable(m_portfolioModel));

        acctPane.setBorder(BorderFactory.createTitledBorder( "Key, Value, Currency, and Account") );
        portPane.setBorder(BorderFactory.createTitledBorder( "Portfolio Entries") );

        JSplitPane splitPane = new JSplitPane(JSplitPane.VERTICAL_SPLIT, acctPane, portPane);
        splitPane.setOneTouchExpandable(true);
        splitPane.setDividerLocation(240);

        splitPane.setPreferredSize(new Dimension(600, 350));

        JPanel timePanel = new JPanel();
        timePanel.add(m_timeLabel);
        timePanel.add(m_updateTime);
        timePanel.add(m_close);

        m_updateTime.setEditable(false);
        m_updateTime.setHorizontalAlignment(JTextField.CENTER);
        m_updateTime.setPreferredSize(new Dimension(80, 26));
        m_close.addActionListener( new ActionListener() {
            public void actionPerformed( ActionEvent e) {
                onClose();
            }
        });

        getContentPane().add( splitPane, BorderLayout.CENTER);
        getContentPane().add( timePanel, BorderLayout.SOUTH);
        setLocation(20, 20);
        pack();
        reset();
    }

    void updateAccountValue(String key, String value, String currency, String accountName) {
        m_acctValueModel.updateAccountValue(key, value, currency, accountName);
    }

    void updatePortfolio(Contract contract, int position, double marketPrice, double marketValue,
    		double averageCost, double unrealizedPNL, double realizedPNL, String accountName) {
       m_portfolioModel.updatePortfolio(contract, position, marketPrice, marketValue,
          averageCost, unrealizedPNL, realizedPNL, accountName);
    }

    void reset() {
        m_acctValueModel.reset();
        m_portfolioModel.reset();
        m_updateTime.setText("");
    }

    void onClose() {
        setVisible( false);
    }

    void updateAccountTime(String timeStamp) {
        m_updateTime.setText(timeStamp);
    }
    
    void accountDownloadBegin(String accountName) {
    	m_accountName = accountName;
    	m_complete = false;
    	
    	updateTitle();
    }
    


	void accountDownloadEnd(String accountName) {
    	
    	if ( !Util.StringIsEmpty( m_accountName) &&
    		 !m_accountName.equals( accountName)) {
    		return;
    	}
    	
    	m_complete = true;
       	updateTitle();
    }
	
    private void updateTitle() {
    	
    	String title = new String();
    	
    	if (!Util.StringIsEmpty( m_accountName)) {
    		title += m_accountName;
    	}
    	if (m_complete) {
    		if (title.length() != 0) {
    			title += ' ';
    		}
    		title += "[complete]";
    	}

		setTitle(title);
	}
}


class PortfolioTable extends AbstractTableModel {
    Vector m_allData = new Vector();

    void updatePortfolio(Contract contract, int position, double marketPrice, double marketValue,
                         double averageCost, double unrealizedPNL, double realizedPNL, String accountName) {
         PortfolioTableRow newData =
         new PortfolioTableRow(contract, position, marketPrice, marketValue, averageCost, unrealizedPNL, realizedPNL, accountName);
         int size = m_allData.size();
         for ( int i = 0; i < size; i++ ) {
             PortfolioTableRow test = (PortfolioTableRow)m_allData.get(i);
             if ( test.m_contract.equals(newData.m_contract) ) {
                 if ( newData.m_position == 0 )
                     m_allData.remove(i);
                 else
                     m_allData.set(i, newData);

                 fireTableDataChanged();
                 return;
             }
         }

         m_allData.add(newData);
         fireTableDataChanged();
    }

    void reset() {
        m_allData.clear();
    }

    public int getRowCount() {
        return m_allData.size();
    }

    public int getColumnCount() {
        return 13;
    }

    public Object getValueAt(int r, int c) {
        return ((PortfolioTableRow) m_allData.get(r)).getValue(c);
    }

    public boolean isCellEditable(int r, int c) {
        return false;
    }

    public String getColumnName(int c) {
        switch(c) {
            case 0:
                return "Symbol";
            case 1:
                return "SecType";
            case 2:
                return "Expiry";
            case 3:
                return "Strike";
            case 4:
                return "Right";
            case 5:
            	return "Multiplier";
            case 6:
            	return "Exchange";
            case 7:
                return "Currency";
            case 8:
                return "Position";
            case 9:
                return "Market Price";
            case 10:
                return "Market Value";
            case 11:
                return "Average Cost";
            case 12:
                return "Unrealized P&L";
            case 13:
                return "Realized P&L";
            case 14:
                return "Account Name";
            default:
                return null;
        }
    }

    class PortfolioTableRow {
        Contract m_contract;
        int      m_position;
        double   m_marketPrice;
        double   m_marketValue;
        double   m_averageCost;
        double   m_unrealizedPNL;
        double   m_realizedPNL;
        String   m_accountName;

        PortfolioTableRow( Contract contract, int position, double marketPrice,
            double marketValue, double averageCost, double unrealizedPNL,
            double realizedPNL, String accountName) {
            m_contract = contract;
            m_position = position;
            m_marketPrice = marketPrice;
            m_marketValue = marketValue;
            m_averageCost = averageCost;
            m_unrealizedPNL = unrealizedPNL;
            m_realizedPNL = realizedPNL;
            m_accountName = accountName;
        }

        Object getValue(int c) {
            switch(c) {
                case 0:
                    return m_contract.m_symbol;
                case 1:
                    return m_contract.m_secType;
                case 2:
                    return m_contract.m_expiry;
                case 3:
                    return m_contract.m_expiry == null ? null : "" + m_contract.m_strike;
                case 4:
                    return (m_contract.m_right != null && m_contract.m_right.equals("???")) ? null : m_contract.m_right;
                case 5:
                	return m_contract.m_multiplier;
                case 6:
                	return (m_contract.m_primaryExch != null ? m_contract.m_primaryExch : "");
                case 7:
                    return m_contract.m_currency;
                case 8:
                    return "" + m_position;
                case 9:
                    return "" + m_marketPrice;
                case 10:
                    return "" + m_marketValue;
                case 11:
                    return "" + m_averageCost;
                case 12:
                    return "" + m_unrealizedPNL;
                case 13:
                    return "" + m_realizedPNL;
                case 14:
                    return m_accountName;
                default:
                    return null;
            }
        }
    }
}

class AcctValueModel extends AbstractTableModel {
    Vector m_allData = new Vector();

    void updateAccountValue(String key, String val, String currency, String accountName) {
         AccountTableRow newData = new AccountTableRow(key, val, currency, accountName);
         int size = m_allData.size();
         for ( int i = 0; i < size; i++ ) {
             AccountTableRow test = (AccountTableRow)m_allData.get(i);
               if (test.m_key != null &&
                   test.m_key.equals(newData.m_key) &&
                   test.m_currency != null &&
                   test.m_currency.equals(newData.m_currency)) {
                 test.m_value = newData.m_value;
                 fireTableDataChanged();
                 return;
               }
         }

         m_allData.add(newData);
         fireTableDataChanged();
    }

    void reset() {
        m_allData.clear();
    }

    public int getRowCount() {
        return m_allData.size();
    }

    public int getColumnCount() {
        return 4;
    }

    public Object getValueAt(int r, int c) {
        return ((AccountTableRow)m_allData.get(r)).getValue(c);
    }


    public boolean isCellEditable(int r, int c) {
        return false;
    }

    public String getColumnName(int c) {
        switch (c) {
            case 0:
                return "Key";
            case 1:
                return "Value";
            case 2:
                return "Currency";
            case 3:
                return "Account Name";

            default:
                return null;
        }
    }

    class AccountTableRow {
        String m_key;
        String m_value;
        String m_currency;
        String m_accountName;

        AccountTableRow(String key, String val, String cur, String accountName) {
            m_key = key;
            m_value = val;
            m_currency = cur;
            m_accountName = accountName ;
        }

        Object getValue(int c) {
            switch (c) {
                case 0:
                    return m_key;
                case 1:
                    return m_value;
                case 2:
                    return m_currency;
                case 3:
                    return m_accountName ;

                default:
                    return null;
            }
        }
    }
}
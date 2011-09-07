package com.ib.client.examples.model;

/**
 * Data object
 *
 * $Id$
 */
public class UnderlyingData {

    private String symbol = null;
    private double minImpVol = 0.0;
    private double volRatioLimit = 0.0;
    private double lastPrice = 0.0;
    private double impVol = 0.0;
    private double histVol = 0.0;

    public UnderlyingData(String symbol, double minImpVol, double volRatioLimit) {
        this.symbol = symbol;
        this.minImpVol = minImpVol;
        this.volRatioLimit = volRatioLimit;
    }

    public String getSymbol() {
        return symbol;
    }

    public void setSymbol(String symbol) {
        this.symbol = symbol;
    }

    public double getVolRatioLimit() {
        return volRatioLimit;
    }

    public void setVolRatioLimit(double volRatioLimit) {
        this.volRatioLimit = volRatioLimit;
    }

    public double getLastPrice() {
        return lastPrice;
    }

    public void setLastPrice(double lastPrice) {
        this.lastPrice = lastPrice;
    }

    public double getImpVol() {
        return impVol;
    }

    public void setImpVol(double impVol) {
        this.impVol = impVol;
    }

    public double getHistVol() {
        return histVol;
    }

    public void setHistVol(double histVol) {
        this.histVol = histVol;
    }

    public boolean isDataReady() {
        if (symbol == null || minImpVol == 0.0 || volRatioLimit == 0.0 || lastPrice == 0.0 || impVol == 0.0 || histVol == 0.0) {
            return false;
        } else {
            return true;
        }
    }

    public boolean isOrderCriteriaMet() {
        if (isDataReady() && impVol >= minImpVol && (impVol / histVol > volRatioLimit)) {
            return true;
        } else {
            return false;
        }
    }

    public String toString() {
        StringBuilder sb = new StringBuilder();

        sb.append("UnderlyingData [ symbol: ").append(symbol);
        sb.append(", minImpVol: ").append(minImpVol);
        sb.append(", volRatioLimit: ").append(volRatioLimit);
        sb.append(", lastPrice: ").append(lastPrice);
        sb.append(", impVol: ").append(impVol);
        sb.append(", histVol: ").append(histVol);
        sb.append(", isDataReady: ").append(isDataReady());
        sb.append(", isOrderCriteriaMet: ").append(impVol).append(" >= ").append(minImpVol).append(" AND ").append((impVol / histVol)).append(" > ").append(volRatioLimit).append(" = ").append(isOrderCriteriaMet()).append(" ]");

        return sb.toString();
    }
    }

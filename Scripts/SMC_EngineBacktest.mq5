// Derived from Smart Money Concepts
// Any redistribution must retain attribution and this license notice.
#property strict

#include <SMC/SMC_Engine.mqh>

input int HistoryBars=5000;
input int SwingLength=50;
input bool InternalConfluenceFilter=false;
input double StopLossATR=1.0;
input double RiskReward=2.0;
input int EvaluationHorizonBars=20;

enum ENUM_BACKTEST_EXIT
{
   BACKTEST_TAKE_PROFIT,
   BACKTEST_STOP_LOSS,
   BACKTEST_TIME_EXIT,
   BACKTEST_AMBIGUOUS_STOP_FIRST
};

struct BacktestTrade
{
   datetime signalTime;
   bool internal;
   bool bullish;
   string tag;
   ENUM_BACKTEST_EXIT exit;
   double resultR;
   int barsHeld;
   bool ambiguous;
};

struct BacktestStats
{
   int trades;
   int wins;
   int losses;
   int breakeven;
   int takeProfits;
   int stopLosses;
   int timeExits;
   int ambiguous;
   double netR;
   double grossProfitR;
   double grossLossR;
};

struct OrderBlockStats
{
   int blocks;
   int bullish;
   int bearish;
   int measuredWidths;
   double totalWidthATR;
};

void AddBacktestTrade(BacktestTrade &trades[],const BacktestTrade &trade)
{
   int count=ArraySize(trades);
   if(ArrayResize(trades,count+1)!=count+1)
   {
      PrintFormat("SMC_BACKTEST ERROR: unable to allocate trade results (error=%d).",
                  GetLastError());
      return;
   }
   trades[count]=trade;
}

void UpdateOrderBlockStats(OrderBlockStats &stats,
                           const OrderBlockState &block,const double atr)
{
   stats.blocks++;
   if(block.bias>0)
      stats.bullish++;
   else
      stats.bearish++;
   if(atr>0.0 && atr<DBL_MAX)
   {
      stats.totalWidthATR+=(block.high-block.low)/atr;
      stats.measuredWidths++;
   }
}

void TrackNewOrderBlocks(const OrderBlockState &orderBlocks[],
                         int &trackedCount,const double atr,
                         OrderBlockStats &allStats,
                         OrderBlockStats &swingStats,
                         OrderBlockStats &internalStats)
{
   for(int i=trackedCount;i<ArraySize(orderBlocks);i++)
   {
      UpdateOrderBlockStats(allStats,orderBlocks[i],atr);
      if(orderBlocks[i].internal)
         UpdateOrderBlockStats(internalStats,orderBlocks[i],atr);
      else
         UpdateOrderBlockStats(swingStats,orderBlocks[i],atr);
   }
   trackedCount=ArraySize(orderBlocks);
}

bool EvaluateSignal(const MqlRates &rates[],const int signalIndex,
                    const StructureEvent &event,const double atr,
                    const int horizon,const double stopLossATR,
                    const double riskReward,BacktestTrade &trade)
{
   int count=ArraySize(rates);
   if(signalIndex-horizon<1 || signalIndex<=0 ||
      !MathIsValidNumber(atr) || atr<=0.0 || atr>=DBL_MAX)
      return false;

   double entry=rates[signalIndex].close;
   double risk=atr*stopLossATR;
   if(!MathIsValidNumber(entry) || !MathIsValidNumber(risk) || risk<=0.0)
      return false;

   double direction=(event.bullish ? 1.0 : -1.0);
   double stop=entry-direction*risk;
   double target=entry+direction*risk*riskReward;
   if(!MathIsValidNumber(stop) || !MathIsValidNumber(target))
      return false;
   int finalIndex=signalIndex-horizon;

   trade.signalTime=event.time;
   trade.internal=event.internal;
   trade.bullish=event.bullish;
   trade.tag=event.tag;
   trade.exit=BACKTEST_TIME_EXIT;
   trade.resultR=0.0;
   trade.barsHeld=horizon;
   trade.ambiguous=false;

   for(int i=signalIndex-1;i>=finalIndex;i--)
   {
      bool stopHit=(event.bullish ? rates[i].low<=stop :
                                   rates[i].high>=stop);
      bool targetHit=(event.bullish ? rates[i].high>=target :
                                     rates[i].low<=target);
      if(stopHit && targetHit)
      {
         trade.exit=BACKTEST_AMBIGUOUS_STOP_FIRST;
         trade.resultR=-1.0;
         trade.barsHeld=signalIndex-i;
         trade.ambiguous=true;
         return true;
      }
      if(stopHit)
      {
         trade.exit=BACKTEST_STOP_LOSS;
         trade.resultR=-1.0;
         trade.barsHeld=signalIndex-i;
         return true;
      }
      if(targetHit)
      {
         trade.exit=BACKTEST_TAKE_PROFIT;
         trade.resultR=riskReward;
         trade.barsHeld=signalIndex-i;
         return true;
      }
   }

   double exitPrice=rates[finalIndex].close;
   trade.resultR=(exitPrice-entry)*direction/risk;
   return true;
}

void UpdateStats(BacktestStats &stats,const BacktestTrade &trade)
{
   stats.trades++;
   stats.netR+=trade.resultR;
   if(trade.resultR>0.0)
   {
      stats.wins++;
      stats.grossProfitR+=trade.resultR;
   }
   else if(trade.resultR<0.0)
   {
      stats.losses++;
      stats.grossLossR+=-trade.resultR;
   }
   else
      stats.breakeven++;

   if(trade.exit==BACKTEST_TAKE_PROFIT)
      stats.takeProfits++;
   else if(trade.exit==BACKTEST_STOP_LOSS ||
           trade.exit==BACKTEST_AMBIGUOUS_STOP_FIRST)
      stats.stopLosses++;
   else
      stats.timeExits++;

   if(trade.ambiguous)
      stats.ambiguous++;
}

void PrintStats(const string label,const BacktestStats &stats)
{
   if(stats.trades==0)
   {
      PrintFormat("SMC_BACKTEST %s: no eligible signals",label);
      return;
   }
   double winRate=100.0*stats.wins/stats.trades;
   double expectancy=stats.netR/stats.trades;
   string profitFactor=(stats.grossLossR>0.0 ?
                        DoubleToString(stats.grossProfitR/stats.grossLossR,3) :
                        "n/a");
   PrintFormat("SMC_BACKTEST %s: trades=%d, win_rate=%.2f%%, expectancy=%.3fR, net=%.2fR, profit_factor=%s, TP=%d, SL=%d, time_exit=%d, ambiguous=%d",
               label,stats.trades,winRate,expectancy,stats.netR,profitFactor,
               stats.takeProfits,stats.stopLosses,stats.timeExits,
               stats.ambiguous);
}

void PrintOrderBlockStats(const string label,const OrderBlockStats &stats)
{
   if(stats.blocks==0)
   {
      PrintFormat("SMC_BACKTEST OB_SELECTION %s: no order blocks",label);
      return;
   }
   string averageWidth=(stats.measuredWidths>0 ?
                        DoubleToString(stats.totalWidthATR/stats.measuredWidths,3) :
                        "n/a");
   PrintFormat("SMC_BACKTEST OB_SELECTION %s: blocks=%d, bullish=%d, bearish=%d, avg_width=%s ATR",
               label,stats.blocks,stats.bullish,stats.bearish,averageWidth);
}

void ProcessStructureEvents(const StructureEvent &events[],const int eventCount,
                            const int signalIndex,const MqlRates &rates[],
                            const double &atrCache[],const int horizon,
                            const double stopLossATR,const double riskReward,
                            BacktestTrade &trades[],int &signalsSkipped)
{
   for(int i=0;i<eventCount;i++)
   {
      BacktestTrade trade;
      if(!EvaluateSignal(rates,signalIndex,events[i],atrCache[signalIndex],
                         horizon,stopLossATR,riskReward,trade))
      {
         signalsSkipped++;
         continue;
      }
      AddBacktestTrade(trades,trade);
   }
}

BacktestStats CollectStats(const BacktestTrade &trades[],
                           const int filterType,const int filterValue)
{
   BacktestStats stats;
   ZeroMemory(stats);
   for(int i=0;i<ArraySize(trades);i++)
   {
      bool matches=true;
      if(filterType==1)
         matches=(trades[i].internal==(filterValue!=0));
      else if(filterType==2)
         matches=(trades[i].tag==(filterValue==0 ? "BOS" : "CHoCH"));
      if(matches)
         UpdateStats(stats,trades[i]);
   }
   return stats;
}

bool LoadChartHistory(MqlRates &rates[],double &open[],double &high[],
                      double &low[],double &close[],datetime &time[])
{
   ArraySetAsSeries(rates,true);
   ResetLastError();
   int copied=CopyRates(_Symbol,_Period,0,HistoryBars,rates);
   if(copied<0)
   {
      PrintFormat("SMC_BACKTEST ERROR: CopyRates failed (error=%d).",
                  GetLastError());
      return false;
   }
   if(copied<MathMax(SwingLength,EvaluationHorizonBars)+10)
   {
      PrintFormat("SMC_BACKTEST ERROR: insufficient history (requested=%d, copied=%d).",
                  HistoryBars,copied);
      return false;
   }

   if(ArrayResize(open,copied)!=copied ||
      ArrayResize(high,copied)!=copied ||
      ArrayResize(low,copied)!=copied ||
      ArrayResize(close,copied)!=copied ||
      ArrayResize(time,copied)!=copied)
   {
      PrintFormat("SMC_BACKTEST ERROR: unable to allocate price arrays (error=%d).",
                  GetLastError());
      return false;
   }
   ArraySetAsSeries(open,true);
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true);
   ArraySetAsSeries(close,true);
   ArraySetAsSeries(time,true);
   for(int i=0;i<copied;i++)
   {
      open[i]=rates[i].open;
      high[i]=rates[i].high;
      low[i]=rates[i].low;
      close[i]=rates[i].close;
      time[i]=rates[i].time;
   }
   return true;
}

bool InitializeCaches(const int count,const double &high[],const double &low[],
                      const double &close[],double &parsedHighs[],
                      double &parsedLows[],double &atrCache[],
                      double &meanRangeCache[],double &trueRangeCache[],
                      double &cumulativeRangeClosedSum)
{
   if(ArrayResize(parsedHighs,count)!=count ||
      ArrayResize(parsedLows,count)!=count ||
      ArrayResize(atrCache,count)!=count ||
      ArrayResize(meanRangeCache,count)!=count ||
      ArrayResize(trueRangeCache,count)!=count)
   {
      PrintFormat("SMC_BACKTEST ERROR: unable to allocate indicator caches (error=%d).",
                  GetLastError());
      return false;
   }
   ArraySetAsSeries(parsedHighs,true);
   ArraySetAsSeries(parsedLows,true);
   ArraySetAsSeries(atrCache,true);
   ArraySetAsSeries(meanRangeCache,true);
   ArraySetAsSeries(trueRangeCache,true);
   return SMC_InitializeCalculationCaches(count,count,high,low,close,
                                          SMC_ATR,parsedHighs,parsedLows,
                                          atrCache,meanRangeCache,trueRangeCache,
                                          cumulativeRangeClosedSum);
}

void OnStart()
{
   if(HistoryBars<MathMax(SwingLength,EvaluationHorizonBars)+10 ||
      SwingLength<10 || EvaluationHorizonBars<1 ||
      StopLossATR<=0.0 || RiskReward<=0.0)
   {
      Print("SMC_BACKTEST ERROR: invalid input parameters.");
      return;
   }

   MqlRates rates[];
   double open[],high[],low[],close[];
   datetime time[];
   if(!LoadChartHistory(rates,open,high,low,close,time))
      return;

   int count=ArraySize(rates);
   double parsedHighs[],parsedLows[],atrCache[],meanRangeCache[],trueRangeCache[];
   double cumulativeRangeClosedSum=0.0;
   if(!InitializeCaches(count,high,low,close,parsedHighs,parsedLows,atrCache,
                        meanRangeCache,trueRangeCache,
                        cumulativeRangeClosedSum))
   {
      Print("SMC_BACKTEST ERROR: failed to initialize calculation caches.");
      return;
   }

   PivotState swingHigh,swingLow,internalHigh,internalLow;
   PivotState trailingTop,trailingBottom;
   ZeroMemory(swingHigh);
   ZeroMemory(swingLow);
   ZeroMemory(internalHigh);
   ZeroMemory(internalLow);
   ZeroMemory(trailingTop);
   ZeroMemory(trailingBottom);
   int swingLeg=0,internalLeg=0;
   int swingBias=0,internalBias=0;
   datetime trailingAnchorTime=0;
   StructureDisplayState latestStructures[4];
   OrderBlockState orderBlocks[];
   BacktestTrade trades[];
   int signalsSkipped=0;
   int trackedOrderBlocks=0;
   OrderBlockStats allOrderBlockStats,swingOrderBlockStats,internalOrderBlockStats;
   ZeroMemory(allOrderBlockStats);
   ZeroMemory(swingOrderBlockStats);
   ZeroMemory(internalOrderBlockStats);

   int oldest=count-1;
   int warmup=MathMax(SwingLength,5);
   for(int i=oldest-warmup-1;i>=1;i--)
   {
      StructureEvent events[2];
      int eventCount=0;
      SMC_DetectStructure(false,SwingLength,swingLeg,swingHigh,swingLow,
                          swingBias,i,count,time,open,high,low,close,false,
                          SMC_SMALL,swingHigh,swingLow,trailingTop,
                          trailingBottom,trailingAnchorTime,parsedHighs,
                          parsedLows,true,orderBlocks,events,eventCount);
      ProcessStructureEvents(events,eventCount,i,rates,atrCache,
                             EvaluationHorizonBars,StopLossATR,RiskReward,
                             trades,signalsSkipped);
      TrackNewOrderBlocks(orderBlocks,trackedOrderBlocks,atrCache[i],
                          allOrderBlockStats,swingOrderBlockStats,
                          internalOrderBlockStats);

      eventCount=0;
      SMC_DetectStructure(true,5,internalLeg,internalHigh,internalLow,
                          internalBias,i,count,time,open,high,low,close,
                          InternalConfluenceFilter,SMC_TINY,
                          swingHigh,swingLow,trailingTop,trailingBottom,
                          trailingAnchorTime,parsedHighs,parsedLows,true,
                          orderBlocks,events,eventCount);
      ProcessStructureEvents(events,eventCount,i,rates,atrCache,
                             EvaluationHorizonBars,StopLossATR,RiskReward,
                             trades,signalsSkipped);
      TrackNewOrderBlocks(orderBlocks,trackedOrderBlocks,atrCache[i],
                          allOrderBlockStats,swingOrderBlockStats,
                          internalOrderBlockStats);
   }

   PrintFormat("SMC_BACKTEST: symbol=%s, timeframe=%s, bars=%d, evaluated_signals=%d, skipped_right_edge_or_invalid=%d, SL=%.2f ATR, TP=%.2fR, horizon=%d closed bars, same-bar collision=SL first",
               _Symbol,EnumToString(_Period),count,ArraySize(trades),
               signalsSkipped,StopLossATR,RiskReward,EvaluationHorizonBars);

   BacktestStats stats=CollectStats(trades,0,0);
   PrintStats("ALL",stats);
   stats=CollectStats(trades,1,0);
   PrintStats("SWING",stats);
   stats=CollectStats(trades,1,1);
   PrintStats("INTERNAL",stats);
   stats=CollectStats(trades,2,0);
   PrintStats("BOS",stats);
   stats=CollectStats(trades,2,1);
   PrintStats("CHoCH",stats);
   PrintOrderBlockStats("ALL",allOrderBlockStats);
   PrintOrderBlockStats("SWING",swingOrderBlockStats);
   PrintOrderBlockStats("INTERNAL",internalOrderBlockStats);
}

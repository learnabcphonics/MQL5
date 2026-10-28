// Derived from Smart Money Concepts
// Any redistribution must retain attribution and this license notice.
#property strict

#include <SMC/SMC_Engine.mqh>

input int HistoryBars=3000;
input int SwingLength=50;

int Passed=0;
int Failed=0;

void CheckTimeframe(const bool condition,const string timeframe,const string test)
{
   if(condition)
   {
      Passed++;
      PrintFormat("SMC_TF_CHECK PASS: %s %s",timeframe,test);
   }
   else
   {
      Failed++;
      PrintFormat("SMC_TF_CHECK FAIL: %s %s",timeframe,test);
   }
}

bool RunTimeframe(const ENUM_TIMEFRAMES timeframe)
{
   string tf=EnumToString(timeframe);
   MqlRates bars[];
   ArraySetAsSeries(bars,true);
   ResetLastError();
   int copied=CopyRates(_Symbol,timeframe,0,HistoryBars,bars);
   if(copied<MathMax(SwingLength,100)+20)
   {
      CheckTimeframe(false,tf,"CopyRates/history availability (copied="+IntegerToString(copied)+")");
      return false;
   }
   CheckTimeframe(true,tf,"history available (bars="+IntegerToString(copied)+")");

   double open[],high[],low[],close[];
   datetime time[];
   if(ArrayResize(open,copied)!=copied || ArrayResize(high,copied)!=copied ||
      ArrayResize(low,copied)!=copied || ArrayResize(close,copied)!=copied ||
      ArrayResize(time,copied)!=copied)
   {
      CheckTimeframe(false,tf,"price array allocation");
      return false;
   }
   ArraySetAsSeries(open,true); ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true); ArraySetAsSeries(close,true);
   ArraySetAsSeries(time,true);
   bool pricesValid=true;
   for(int i=0;i<copied;i++)
   {
      open[i]=bars[i].open; high[i]=bars[i].high;
      low[i]=bars[i].low; close[i]=bars[i].close; time[i]=bars[i].time;
      if(!MathIsValidNumber(open[i]) || !MathIsValidNumber(high[i]) ||
         !MathIsValidNumber(low[i]) || !MathIsValidNumber(close[i]) ||
         high[i]<low[i]) pricesValid=false;
   }
   CheckTimeframe(pricesValid,tf,"OHLC values and high>=low");

   SMC_State state;
   if(ArrayResize(state.ParsedHighs,copied)!=copied ||
      ArrayResize(state.ParsedLows,copied)!=copied ||
      ArrayResize(state.AtrCache,copied)!=copied ||
      ArrayResize(state.MeanRangeCache,copied)!=copied ||
      ArrayResize(state.TrueRangeCache,copied)!=copied)
   {
      CheckTimeframe(false,tf,"engine cache allocation");
      return false;
   }
   ArraySetAsSeries(state.ParsedHighs,true); ArraySetAsSeries(state.ParsedLows,true);
   ArraySetAsSeries(state.AtrCache,true); ArraySetAsSeries(state.MeanRangeCache,true);
   ArraySetAsSeries(state.TrueRangeCache,true);
   bool cacheOk=SMC_InitializeCalculationCaches(copied,copied,high,low,close,
                                                SMC_ATR,state);
   CheckTimeframe(cacheOk,tf,"ATR engine cache initialization");
   if(!cacheOk) return false;

   int oldest=copied-1;
   bool noNaN=true;
   for(int i=oldest-SwingLength;i>=2;i--)
   {
      StructureEvent events[2];
      int eventCount=0;
      SMC_DetectStructure(false,SwingLength,i,copied,time,open,high,low,close,
                          false,SMC_SMALL,true,state,events,eventCount);
      if(state.SwingHigh.initialized && !MathIsValidNumber(state.SwingHigh.current))
         noNaN=false;
      if(state.SwingLow.initialized && !MathIsValidNumber(state.SwingLow.current))
         noNaN=false;
   }
   CheckTimeframe(noNaN,tf,"swing structure loop without engine failure");

   bool fvgOk=SMC_AnalyzeHistoricalFVG(bars,false,20,PeriodSeconds(timeframe),
                                       _Point,state);
   CheckTimeframe(fvgOk,tf,"historical FVG analysis completes");
   bool fvgGeometry=true;
   for(int i=0;i<ArraySize(state.FairValueGaps);i++)
   {
      FairValueGapState gap=state.FairValueGaps[i];
      if(!MathIsValidNumber(gap.top) || !MathIsValidNumber(gap.bottom) ||
         gap.top<gap.bottom || gap.left<=0 || gap.right<=gap.left)
         fvgGeometry=false;
   }
   CheckTimeframe(fvgGeometry,tf,"FVG price/time geometry invariants");

   bool obGeometry=true;
   for(int i=0;i<ArraySize(state.OrderBlocks);i++)
   {
      OrderBlockState block=state.OrderBlocks[i];
      if(!MathIsValidNumber(block.high) || !MathIsValidNumber(block.low) ||
         block.high<block.low || block.created<=0 || block.time<=0 ||
         (block.bias!=1 && block.bias!=-1))
         obGeometry=false;
   }
   CheckTimeframe(obGeometry,tf,"OB price/time/bias invariants");
   return true;
}

void OnStart()
{
   Passed=0; Failed=0;
   ENUM_TIMEFRAMES tf[] = {PERIOD_M1,PERIOD_M5,PERIOD_M15,PERIOD_M30,
                            PERIOD_H1,PERIOD_H4,PERIOD_D1,PERIOD_W1,PERIOD_MN1};
   for(int i=0;i<ArraySize(tf);i++)
      RunTimeframe(tf[i]);
   PrintFormat("SMC_TF_CHECK SUMMARY: symbol=%s, passed=%d, failed=%d",
               _Symbol,Passed,Failed);
}

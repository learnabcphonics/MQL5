// Derived from Smart Money Concepts
// Any redistribution must retain attribution and this license notice.
#property strict

#include <SMC/SMC_Engine.mqh>

int TestsPassed=0;
int TestsFailed=0;

void Check(const bool condition,const string testName)
{
   if(condition)
   {
      TestsPassed++;
      PrintFormat("SMC_ENGINE_TEST PASS: %s",testName);
   }
   else
   {
      TestsFailed++;
      PrintFormat("SMC_ENGINE_TEST FAIL: %s",testName);
   }
}

void InitializeBars(const int count,datetime &time[],double &open[],
                    double &high[],double &low[],double &close[])
{
   ArrayResize(time,count);
   ArrayResize(open,count);
   ArrayResize(high,count);
   ArrayResize(low,count);
   ArrayResize(close,count);
   for(int i=0;i<count;i++)
   {
      time[i]=(datetime)(1700000000-i*60);
      open[i]=6.0;
      high[i]=10.0;
      low[i]=5.0;
      close[i]=6.0;
   }
}

void RunStructureDetection(int &legState,PivotState &pivotHigh,
                           PivotState &pivotLow,int &bias,
                           const int i,const int ratesTotal,
                           const datetime &time[],const double &open[],
                           const double &high[],const double &low[],
                           const double &close[],
                           const double &parsedHighs[],
                           const double &parsedLows[],
                           PivotState &trailingTop,
                           PivotState &trailingBottom,
                           datetime &trailingAnchorTime,
                           StructureEvent &events[],int &eventCount,
                           OrderBlockState &orderBlocks[])
{
   SMC_State state;
   state.SwingLeg=legState;
   state.SwingHigh=pivotHigh;
   state.SwingLow=pivotLow;
   state.SwingBias=bias;
   state.TrailingTop=trailingTop;
   state.TrailingBottom=trailingBottom;
   state.TrailingAnchorTime=trailingAnchorTime;
   int parsedCount=ArraySize(parsedHighs);
   ArrayResize(state.ParsedHighs,parsedCount);
   ArrayResize(state.ParsedLows,parsedCount);
   ArrayCopy(state.ParsedHighs,parsedHighs);
   ArrayCopy(state.ParsedLows,parsedLows);
   int blockCount=ArraySize(orderBlocks);
   ArrayResize(state.OrderBlocks,blockCount);
   ArrayCopy(state.OrderBlocks,orderBlocks);
   SMC_DetectStructure(false,2,i,ratesTotal,time,open,high,low,close,false,
                       SMC_SMALL,false,state,events,eventCount);
   legState=state.SwingLeg;
   pivotHigh=state.SwingHigh;
   pivotLow=state.SwingLow;
   bias=state.SwingBias;
   trailingTop=state.TrailingTop;
   trailingBottom=state.TrailingBottom;
   trailingAnchorTime=state.TrailingAnchorTime;
   ArrayResize(orderBlocks,ArraySize(state.OrderBlocks));
   ArrayCopy(orderBlocks,state.OrderBlocks);
}

void TestPivotLowConfirmation()
{
   datetime time[];
   double open[],high[],low[],close[],parsedHighs[],parsedLows[];
   InitializeBars(8,time,open,high,low,close);
   ArrayResize(parsedHighs,8);
   ArrayResize(parsedLows,8);
   for(int i=0;i<8;i++)
   {
      parsedHighs[i]=high[i];
      parsedLows[i]=low[i];
   }
   high[1]=12.0; high[2]=11.0; high[3]=10.0;
   low[1]=8.0; low[2]=7.0; low[3]=5.0;

   PivotState pivotHigh,pivotLow,trailingTop,trailingBottom;
   ZeroMemory(pivotHigh);
   ZeroMemory(pivotLow);
   ZeroMemory(trailingTop);
   ZeroMemory(trailingBottom);
   int legState=0,bias=0,eventCount=0;
   datetime trailingAnchorTime=0;
   StructureEvent events[];
   OrderBlockState orderBlocks[];
   ArrayResize(events,2);
   int parsedCount=ArraySize(parsedHighs);
   for(int i=0;i<parsedCount;i++)
   {
      parsedHighs[i]=high[i];
      parsedLows[i]=low[i];
   }

   RunStructureDetection(legState,pivotHigh,pivotLow,bias,1,8,time,open,high,
                         low,close,parsedHighs,parsedLows,trailingTop,
                         trailingBottom,trailingAnchorTime,events,eventCount,
                         orderBlocks);
   Check(legState==1 && pivotLow.initialized && pivotLow.current==5.0 &&
         pivotLow.time==time[3] && !pivotHigh.initialized,
         "confirms pivot low when the leg reverses");
}

void TestPivotHighConfirmation()
{
   datetime time[];
   double open[],high[],low[],close[],parsedHighs[],parsedLows[];
   InitializeBars(8,time,open,high,low,close);
   ArrayResize(parsedHighs,8);
   ArrayResize(parsedLows,8);
   high[1]=12.0; high[2]=11.0; high[3]=20.0;
   low[1]=8.0; low[2]=7.0; low[3]=7.0;
   for(int i=0;i<8;i++)
   {
      parsedHighs[i]=high[i];
      parsedLows[i]=low[i];
   }

   PivotState pivotHigh,pivotLow,trailingTop,trailingBottom;
   ZeroMemory(pivotHigh);
   ZeroMemory(pivotLow);
   ZeroMemory(trailingTop);
   ZeroMemory(trailingBottom);
   int legState=1,bias=0,eventCount=0;
   datetime trailingAnchorTime=0;
   StructureEvent events[];
   OrderBlockState orderBlocks[];
   ArrayResize(events,2);

   RunStructureDetection(legState,pivotHigh,pivotLow,bias,1,8,time,open,high,
                         low,close,parsedHighs,parsedLows,trailingTop,
                         trailingBottom,trailingAnchorTime,events,eventCount,
                         orderBlocks);
   Check(legState==0 && pivotHigh.initialized && pivotHigh.current==20.0 &&
         pivotHigh.time==time[3] && !pivotLow.initialized,
         "confirms pivot high when the leg reverses");
}

void TestOutsideBarPriority()
{
   datetime time[];
   double open[],high[],low[],close[],parsedHighs[],parsedLows[];
   InitializeBars(8,time,open,high,low,close);
   ArrayResize(parsedHighs,8);
   ArrayResize(parsedLows,8);
   high[1]=12.0; high[2]=11.0; high[3]=20.0;
   low[1]=8.0; low[2]=7.0; low[3]=4.0;
   for(int i=0;i<8;i++)
   {
      parsedHighs[i]=high[i];
      parsedLows[i]=low[i];
   }

   PivotState pivotHigh,pivotLow,trailingTop,trailingBottom;
   ZeroMemory(pivotHigh);
   ZeroMemory(pivotLow);
   ZeroMemory(trailingTop);
   ZeroMemory(trailingBottom);
   int legState=1,bias=0,eventCount=0;
   datetime trailingAnchorTime=0;
   StructureEvent events[];
   OrderBlockState orderBlocks[];
   ArrayResize(events,2);

   RunStructureDetection(legState,pivotHigh,pivotLow,bias,1,8,time,open,high,
                         low,close,parsedHighs,parsedLows,trailingTop,
                         trailingBottom,trailingAnchorTime,events,eventCount,
                         orderBlocks);
   Check(legState==0 && pivotHigh.initialized && pivotHigh.current==20.0 &&
         !pivotLow.initialized,
         "outside bar that breaks both extremes prioritizes pivot high");
}

void TestWickDoesNotBreakStructure()
{
   datetime time[];
   double open[],high[],low[],close[],parsedHighs[],parsedLows[];
   InitializeBars(8,time,open,high,low,close);
   ArrayResize(parsedHighs,8);
   ArrayResize(parsedLows,8);
   high[1]=101.0;
   close[1]=99.5;
   close[2]=99.0;
   for(int i=0;i<8;i++)
   {
      parsedHighs[i]=high[i];
      parsedLows[i]=low[i];
   }

   PivotState pivotHigh,pivotLow,trailingTop,trailingBottom;
   ZeroMemory(pivotHigh);
   ZeroMemory(pivotLow);
   ZeroMemory(trailingTop);
   ZeroMemory(trailingBottom);
   pivotHigh.initialized=true;
   pivotHigh.current=100.0;
   pivotHigh.time=time[4];
   pivotHigh.index=4;
   int legState=0,bias=0,eventCount=0;
   datetime trailingAnchorTime=0;
   StructureEvent events[];
   OrderBlockState orderBlocks[];
   ArrayResize(events,2);

   RunStructureDetection(legState,pivotHigh,pivotLow,bias,1,8,time,open,high,
                         low,close,parsedHighs,parsedLows,trailingTop,
                         trailingBottom,trailingAnchorTime,events,eventCount,
                         orderBlocks);
   Check(eventCount==0 && !pivotHigh.crossed && bias==0,
         "wick through pivot without close does not create a break");
}

void TestCloseBreakAndClassification()
{
   datetime time[];
   double open[],high[],low[],close[],parsedHighs[],parsedLows[];
   InitializeBars(8,time,open,high,low,close);
   ArrayResize(parsedHighs,8);
   ArrayResize(parsedLows,8);
   close[1]=100.5;
   close[2]=99.5;
   for(int i=0;i<8;i++)
   {
      parsedHighs[i]=high[i];
      parsedLows[i]=low[i];
   }

   PivotState pivotHigh,pivotLow,trailingTop,trailingBottom;
   ZeroMemory(pivotHigh);
   ZeroMemory(pivotLow);
   ZeroMemory(trailingTop);
   ZeroMemory(trailingBottom);
   pivotHigh.initialized=true;
   pivotHigh.current=100.0;
   pivotHigh.time=time[4];
   pivotHigh.index=4;
   int legState=0,bias=0,eventCount=0;
   datetime trailingAnchorTime=0;
   StructureEvent events[];
   OrderBlockState orderBlocks[];
   ArrayResize(events,2);

   RunStructureDetection(legState,pivotHigh,pivotLow,bias,1,8,time,open,high,
                         low,close,parsedHighs,parsedLows,trailingTop,
                         trailingBottom,trailingAnchorTime,events,eventCount,
                         orderBlocks);
   Check(eventCount==1 && events[0].bullish && events[0].tag=="BOS" &&
         pivotHigh.crossed && bias==1,
         "close above pivot creates bullish BOS from neutral bias");

   ZeroMemory(pivotHigh);
   ZeroMemory(pivotLow);
   ZeroMemory(trailingTop);
   ZeroMemory(trailingBottom);
   pivotHigh.initialized=true;
   pivotHigh.current=100.0;
   pivotHigh.time=time[4];
   pivotHigh.index=4;
   legState=0;
   bias=-1;
   eventCount=0;
   ArrayResize(orderBlocks,0);

   RunStructureDetection(legState,pivotHigh,pivotLow,bias,1,8,time,open,high,
                         low,close,parsedHighs,parsedLows,trailingTop,
                         trailingBottom,trailingAnchorTime,events,eventCount,
                         orderBlocks);
   Check(eventCount==1 && events[0].tag=="CHoCH" && bias==1,
         "close above pivot against bearish bias creates CHoCH");
}

void TestCrossedPivotIsNotRepeated()
{
   datetime time[];
   double open[],high[],low[],close[],parsedHighs[],parsedLows[];
   InitializeBars(8,time,open,high,low,close);
   ArrayResize(parsedHighs,8);
   ArrayResize(parsedLows,8);
   close[1]=100.5;
   close[2]=99.5;
   for(int i=0;i<8;i++)
   {
      parsedHighs[i]=high[i];
      parsedLows[i]=low[i];
   }

   PivotState pivotHigh,pivotLow,trailingTop,trailingBottom;
   ZeroMemory(pivotHigh);
   ZeroMemory(pivotLow);
   ZeroMemory(trailingTop);
   ZeroMemory(trailingBottom);
   pivotHigh.initialized=true;
   pivotHigh.current=100.0;
   pivotHigh.crossed=true;
   pivotHigh.index=4;
   int legState=0,bias=1,eventCount=0;
   datetime trailingAnchorTime=0;
   StructureEvent events[];
   OrderBlockState orderBlocks[];
   ArrayResize(events,2);

   RunStructureDetection(legState,pivotHigh,pivotLow,bias,1,8,time,open,high,
                         low,close,parsedHighs,parsedLows,trailingTop,
                         trailingBottom,trailingAnchorTime,events,eventCount,
                         orderBlocks);
   Check(eventCount==0 && bias==1,
         "already-crossed pivot cannot emit the same event again");
}

void TestBullishOrderBlockSelection()
{
   datetime time[];
   double open[],high[],low[],close[];
   InitializeBars(8,time,open,high,low,close);
   double parsedHighs[],parsedLows[];
   ArrayResize(parsedHighs,8);
   ArrayResize(parsedLows,8);
   for(int i=0;i<8;i++)
   {
      parsedHighs[i]=20.0+i;
      parsedLows[i]=10.0+i;
   }
   parsedLows[2]=7.0;
   parsedLows[3]=5.0;
   parsedLows[4]=2.0;
   parsedLows[5]=6.0;
   parsedLows[6]=8.0;
   parsedHighs[4]=1.0;

   PivotState pivot;
   ZeroMemory(pivot);
   pivot.index=6;
   OrderBlockState orderBlocks[];
   SMC_StoreOrderBlock(pivot,false,1,time,parsedHighs,parsedLows,8,1,true,
                       orderBlocks);
   Check(ArraySize(orderBlocks)==1 && orderBlocks[0].time==time[4] &&
         orderBlocks[0].high==2.0 && orderBlocks[0].low==1.0 &&
         orderBlocks[0].created==time[1],
         "bullish OB selects minimum parsed low and normalizes zone bounds");
}

void TestBearishOrderBlockSelection()
{
   datetime time[];
   double open[],high[],low[],close[];
   InitializeBars(8,time,open,high,low,close);
   double parsedHighs[],parsedLows[];
   ArrayResize(parsedHighs,8);
   ArrayResize(parsedLows,8);
   for(int i=0;i<8;i++)
   {
      parsedHighs[i]=20.0+i;
      parsedLows[i]=10.0+i;
   }
   parsedHighs[2]=27.0;
   parsedHighs[3]=29.0;
   parsedHighs[4]=25.0;
   parsedHighs[5]=31.0;
   parsedHighs[6]=28.0;
   parsedLows[5]=25.0;

   PivotState pivot;
   ZeroMemory(pivot);
   pivot.index=6;
   OrderBlockState orderBlocks[];
   SMC_StoreOrderBlock(pivot,false,-1,time,parsedHighs,parsedLows,8,1,true,
                       orderBlocks);
   Check(ArraySize(orderBlocks)==1 && orderBlocks[0].time==time[5] &&
         orderBlocks[0].high==31.0 && orderBlocks[0].low==25.0 &&
         orderBlocks[0].created==time[1],
         "bearish OB selects maximum parsed high");
}

void TestVolatilityParsedExtremes()
{
   int count=250;
   double high[],low[],close[],parsedHighs[],parsedLows[];
   SMC_State state;
   ArrayResize(high,count);
   ArrayResize(low,count);
   ArrayResize(close,count);
   ArrayResize(state.ParsedHighs,count);
   ArrayResize(state.ParsedLows,count);
   ArrayResize(state.AtrCache,count);
   ArrayResize(state.MeanRangeCache,count);
   ArrayResize(state.TrueRangeCache,count);
   for(int i=0;i<count;i++)
   {
      high[i]=101.0;
      low[i]=100.0;
      close[i]=100.5;
   }
   high[4]=110.0;

   bool initialized=SMC_InitializeCalculationCaches(count,count,high,low,close,
                                                    SMC_ATR,state);
   Check(initialized && state.ParsedHighs[4]==low[4] &&
         state.ParsedLows[4]==high[4] && state.ParsedHighs[3]==high[3] &&
         state.ParsedLows[3]==low[3],
         "ATR filter swaps parsed extremes only on the volatile bar");
}

void OnStart()
{
   TestsPassed=0;
   TestsFailed=0;
   Print("SMC_ENGINE_TEST: starting synthetic Engine tests");

   TestPivotLowConfirmation();
   TestPivotHighConfirmation();
   TestOutsideBarPriority();
   TestWickDoesNotBreakStructure();
   TestCloseBreakAndClassification();
   TestCrossedPivotIsNotRepeated();
   TestBullishOrderBlockSelection();
   TestBearishOrderBlockSelection();
   TestVolatilityParsedExtremes();

   PrintFormat("SMC_ENGINE_TEST SUMMARY: %d passed, %d failed",
               TestsPassed,TestsFailed);
}

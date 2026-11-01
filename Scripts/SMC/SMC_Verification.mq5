#property script_show_inputs

#include <SMC/SMC_Types.mqh>
#include <SMC/SMC_State.mqh>
#include <SMC/SMC_Config.mqh>
#include <SMC/SMC_Palette.mqh>
#include <SMC/SMC_OrderBlock.mqh>
#include <SMC/SMC_Structure.mqh>
#include <SMC/SMC_FVG.mqh>
#include <SMC/SMC_Calculation.mqh>
#include <SMC/SMC_Draw.mqh>

input int SymbolsToTest=3;
input int BarsPerDataset=10000;

int SMC_VerificationCases=0;
int SMC_VerificationFailures=0;
int SMC_VerificationSkips=0;

void SMC_Verify(const string name,const bool passed)
{
   SMC_VerificationCases++;
   if(passed)
      PrintFormat("SMC_TEST PASS | %s",name);
   else
   {
      SMC_VerificationFailures++;
      PrintFormat("SMC_TEST FAIL | %s",name);
   }
}

void SMC_VerifyStructureBreak(const bool bullish,const int initialBias,
                              const string expectedTag)
{
   datetime times[5];
   double open[5],high[5],low[5],close[5];
   double parsedHighs[5],parsedLows[5];
   for(int i=0;i<5;i++)
   {
      times[i]=1000-i*60;
      open[i]=9.0;
      high[i]=9.0;
      low[i]=8.0;
      close[i]=9.0;
      parsedHighs[i]=high[i];
      parsedLows[i]=low[i];
   }
   close[1]=(bullish ? 11.0 : 7.0);
   close[2]=(bullish ? 9.0 : 11.0);

   PivotState pivotHigh,pivotLow,swingHigh,swingLow;
   PivotState trailingTop,trailingBottom;
   ZeroMemory(pivotHigh);
   ZeroMemory(pivotLow);
   ZeroMemory(swingHigh);
   ZeroMemory(swingLow);
   ZeroMemory(trailingTop);
   ZeroMemory(trailingBottom);
   if(bullish)
   {
      pivotHigh.initialized=true;
      pivotHigh.current=10.0;
   }
   else
   {
      pivotLow.initialized=true;
      pivotLow.current=10.0;
   }

   int legState=1;
   int trendBias=initialBias;
   datetime trailingAnchor=0;
   OrderBlockState orderBlocks[];
   StructureEvent events[2];
   int eventCount=0;
   SMC_DetectStructureCore(false,2,legState,pivotHigh,pivotLow,trendBias,
                            1,5,times,open,high,low,close,false,SMC_SMALL,
                            swingHigh,swingLow,trailingTop,trailingBottom,
                            trailingAnchor,parsedHighs,parsedLows,false,
                            orderBlocks,events,eventCount);

   bool passed=(eventCount==1 && events[0].tag==expectedTag &&
                events[0].bullish==bullish &&
                trendBias==(bullish ? 1 : -1));
   string direction=(bullish ? "bullish" : "bearish");
   SMC_Verify("structure "+direction+" break classified "+expectedTag,passed);

   if(eventCount==1)
   {
      eventCount=-1;
      SMC_DetectStructureCore(false,2,legState,pivotHigh,pivotLow,trendBias,
                               1,5,times,open,high,low,close,false,SMC_SMALL,
                               swingHigh,swingLow,trailingTop,trailingBottom,
                               trailingAnchor,parsedHighs,parsedLows,false,
                               orderBlocks,events,eventCount);
      SMC_Verify("structure pivot does not emit duplicate break",eventCount==0);
   }
}

void SMC_TestStructureClassification()
{
   SMC_VerifyStructureBreak(true,0,"BOS");
   SMC_VerifyStructureBreak(true,-1,"CHoCH");
   SMC_VerifyStructureBreak(false,0,"BOS");
   SMC_VerifyStructureBreak(false,1,"CHoCH");
}

void SMC_TestOrderBlockMitigation()
{
   SMC_State state;
   if(!SMC_ResetState(state))
   {
      SMC_Verify("order block mitigation state reset",false);
      return;
   }
   if(ArrayResize(state.OrderBlocks,2)!=2)
   {
      SMC_Verify("order block mitigation fixture allocation",false);
      return;
   }

   state.OrderBlocks[0].high=105.0;
   state.OrderBlocks[0].low=95.0;
   state.OrderBlocks[0].created=900;
   state.OrderBlocks[0].bias=1;
   state.OrderBlocks[1].high=105.0;
   state.OrderBlocks[1].low=95.0;
   state.OrderBlocks[1].created=1000;
   state.OrderBlocks[1].bias=1;

   OrderBlockState removed[];
   int removedCount=0;
   bool updated=SMC_RemoveMitigatedOrderBlocks(110.0,90.0,100.0,1000,
                                                SMC_HIGH_LOW,state,
                                                removed,removedCount);
   SMC_Verify("mitigated OB is removed while same-bar OB is retained",
              updated && removedCount==1 &&
              ArraySize(state.OrderBlocks)==1 &&
              state.OrderBlocks[0].created==1000);
}

void SMC_TestFVGMitigation()
{
   SMC_State state;
   if(!SMC_ResetState(state))
   {
      SMC_Verify("FVG mitigation state reset",false);
      return;
   }
   bool added=SMC_AddFairValueGap(900,1,95.0,100.0,900,1500,
                                  100.0,97.5,97.5,95.0,
                                  state.FairValueGaps);
   if(!added)
   {
      SMC_Verify("FVG mitigation fixture creation",false);
      return;
   }

   MqlRates bars[4];
   for(int i=0;i<4;i++)
   {
      ZeroMemory(bars[i]);
      bars[i].time=1000-i*60;
   }
   bars[0].low=94.0;
   FairValueGapState removed[];
   int removedCount=0;
   bool updated=SMC_UpdateFairValueGaps(bars,1000,60,1,false,0.00001,
                                        state,removed,removedCount);
   SMC_Verify("mitigated bullish FVG is returned and removed from state",
              updated && removedCount==1 &&
              ArraySize(state.FairValueGaps)==0 &&
              removed[0].time==900);
}

int SMC_CountObjectsWithPrefix(const string prefix)
{
   int count=0;
   for(int i=ObjectsTotal(0,-1,-1)-1;i>=0;i--)
      if(StringFind(ObjectName(0,i,-1,-1),prefix)==0)
         count++;
   return count;
}

void SMC_TestChartObjectLifecycle()
{
   string prefix="SMC_TEST_"+IntegerToString((long)ChartID())+"_"+
                 IntegerToString((int)GetTickCount())+"_";
   SMC_DrawConfig config;
   ZeroMemory(config);
   config.objectPrefix=prefix;
   config.chartTimeframe=_Period;

   double point=SymbolInfoDouble(_Symbol,SYMBOL_POINT);
   if(point<=0.0)
      point=0.00001;
   double top=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   if(top<=0.0)
      top=1.0;
   datetime left=TimeCurrent()-MathMax(60,PeriodSeconds(_Period));

   FairValueGapState gap;
   ZeroMemory(gap);
   gap.time=left;
   gap.left=left;
   gap.right=left+MathMax(60,PeriodSeconds(_Period))*10;
   gap.bias=1;
   gap.top=top;
   gap.bottom=top-10.0*point;
   gap.firstTop=gap.top;
   gap.firstBottom=(gap.top+gap.bottom)*0.5;
   gap.secondTop=gap.firstBottom;
   gap.secondBottom=gap.bottom;

   SMC_DrawFairValueGap(config,gap,SMC_COLOR_BULLISH);
   SMC_DrawFairValueGap(config,gap,SMC_COLOR_BULLISH);
   SMC_Verify("repeated FVG render does not duplicate its 3 objects",
              SMC_CountObjectsWithPrefix(prefix)==3);

   SMC_DeleteFairValueGap(config,gap);
   SMC_Verify("FVG deletion removes all its chart objects",
              SMC_CountObjectsWithPrefix(prefix)==0);

   SMC_DrawZoneBox(prefix+"ZONE",left,gap.right,gap.top,gap.bottom,
                   SMC_COLOR_EQUILIBRIUM);
   SMC_ClearObjects(prefix);
   SMC_Verify("prefix cleanup leaves no test chart objects",
              SMC_CountObjectsWithPrefix(prefix)==0);
}

void SMC_SkipDataset(const string symbol,const ENUM_TIMEFRAMES timeframe,
                     const string reason)
{
   SMC_VerificationSkips++;
   PrintFormat("SMC_TEST SKIP | %s %s | %s",
               symbol,EnumToString(timeframe),reason);
}

void SMC_TestMarketDataMatrix()
{
   string symbols[];
   if(ArrayResize(symbols,1)!=1)
   {
      Print("SMC_TEST FAIL | unable to allocate symbol list");
      SMC_VerificationFailures++;
      return;
   }
   symbols[0]=_Symbol;

   int symbolLimit=MathMax(1,MathMin(SymbolsToTest,10));
   int availableSymbols=SymbolsTotal(true);
   for(int i=0;i<availableSymbols && ArraySize(symbols)<symbolLimit;i++)
   {
      string candidate=SymbolName(i,true);
      if(candidate=="" || candidate==_Symbol)
         continue;
      int count=ArraySize(symbols);
      if(ArrayResize(symbols,count+1)!=count+1)
      {
         Print("SMC_TEST FAIL | unable to grow symbol list");
         SMC_VerificationFailures++;
         return;
      }
      symbols[count]=candidate;
   }

   ENUM_TIMEFRAMES timeframes[5];
   timeframes[0]=PERIOD_M5;
   timeframes[1]=PERIOD_M15;
   timeframes[2]=PERIOD_H1;
   timeframes[3]=PERIOD_H4;
   timeframes[4]=PERIOD_D1;

   int maxBars=MathMax(2,MathMin(BarsPerDataset,10000));
   int minimumBars=MathMin(maxBars,1000);
   for(int s=0;s<ArraySize(symbols);s++)
   {
      string symbol=symbols[s];
      for(int t=0;t<ArraySize(timeframes);t++)
      {
         ENUM_TIMEFRAMES timeframe=timeframes[t];
         MqlRates bars[];
         ArraySetAsSeries(bars,true);
         ResetLastError();
         int copied=CopyRates(symbol,timeframe,0,maxBars,bars);
         if(copied<minimumBars)
         {
            SMC_SkipDataset(symbol,timeframe,
                            StringFormat("need at least %d bars, copied %d (error %d)",
                                         minimumBars,copied,GetLastError()));
            continue;
         }

         double high[],low[],close[];
         if(ArrayResize(high,copied)!=copied ||
            ArrayResize(low,copied)!=copied ||
            ArrayResize(close,copied)!=copied)
         {
            SMC_Verify(symbol+" "+EnumToString(timeframe)+
                       " price-array allocation",false);
            continue;
         }
         ArraySetAsSeries(high,true);
         ArraySetAsSeries(low,true);
         ArraySetAsSeries(close,true);
         for(int i=0;i<copied;i++)
         {
            high[i]=bars[i].high;
            low[i]=bars[i].low;
            close[i]=bars[i].close;
         }

         SMC_State state;
         if(!SMC_ResetState(state))
         {
            SMC_Verify(symbol+" "+EnumToString(timeframe)+
                       " calculation state reset",false);
            continue;
         }
         if(ArrayResize(state.AtrCache,copied)!=copied ||
            ArrayResize(state.MeanRangeCache,copied)!=copied ||
            ArrayResize(state.TrueRangeCache,copied)!=copied ||
            ArrayResize(state.ParsedHighs,copied)!=copied ||
            ArrayResize(state.ParsedLows,copied)!=copied)
         {
            SMC_Verify(symbol+" "+EnumToString(timeframe)+
                       " cache allocation",false);
            continue;
         }
         ArraySetAsSeries(state.AtrCache,true);
         ArraySetAsSeries(state.MeanRangeCache,true);
         ArraySetAsSeries(state.TrueRangeCache,true);
         ArraySetAsSeries(state.ParsedHighs,true);
         ArraySetAsSeries(state.ParsedLows,true);

         ulong start=GetMicrosecondCount();
         bool initialized=SMC_InitializeCalculationCaches(
                             copied,copied,high,low,close,SMC_ATR,state);
         ulong initializeMicros=GetMicrosecondCount()-start;
         bool validCaches=initialized &&
                          ArraySize(state.AtrCache)==copied &&
                          ArraySize(state.ParsedHighs)==copied &&
                          MathIsValidNumber(state.AtrCache[0]) &&
                          state.AtrCache[0]<DBL_MAX &&
                          MathIsValidNumber(state.ParsedHighs[0]);
         SMC_Verify(symbol+" "+EnumToString(timeframe)+
                    " historical cache initialization",validCaches);
         if(!validCaches)
            continue;

         state.LastRatesTotal=copied;
         double nextHigh[],nextLow[],nextClose[];
         if(ArrayResize(nextHigh,copied+1)!=copied+1 ||
            ArrayResize(nextLow,copied+1)!=copied+1 ||
            ArrayResize(nextClose,copied+1)!=copied+1)
         {
            SMC_Verify(symbol+" "+EnumToString(timeframe)+
                       " incremental-array allocation",false);
            continue;
         }
         ArraySetAsSeries(nextHigh,true);
         ArraySetAsSeries(nextLow,true);
         ArraySetAsSeries(nextClose,true);
         for(int i=0;i<copied;i++)
         {
            nextHigh[i+1]=high[i];
            nextLow[i+1]=low[i];
            nextClose[i+1]=close[i];
         }
         double point=SymbolInfoDouble(symbol,SYMBOL_POINT);
         if(point<=0.0)
            point=0.00001;
         double range=MathMax(point,bars[0].high-bars[0].low);
         nextHigh[0]=bars[0].close+range*0.25;
         nextLow[0]=MathMax(point,bars[0].close-range*0.25);
         nextClose[0]=bars[0].close;

         start=GetMicrosecondCount();
         bool advanced=SMC_AdvanceCalculationCaches(
                          copied+1,maxBars,nextHigh,nextLow,nextClose,
                          SMC_ATR,state);
         ulong advanceMicros=GetMicrosecondCount()-start;
         bool validAdvance=advanced &&
                           ArraySize(state.AtrCache)==MathMin(copied+1,maxBars) &&
                           MathIsValidNumber(state.AtrCache[0]) &&
                           state.AtrCache[0]<DBL_MAX &&
                           MathIsValidNumber(state.ParsedHighs[0]);
         SMC_Verify(symbol+" "+EnumToString(timeframe)+
                    " incremental cache update",validAdvance);
         PrintFormat("SMC_TEST PERF | %s %s | bars=%d init_us=%I64u advance_us=%I64u",
                     symbol,EnumToString(timeframe),copied,
                     initializeMicros,advanceMicros);
      }
   }
}

void OnStart()
{
   Print("SMC_TEST BEGIN | deterministic regressions, chart-object lifecycle, market-data matrix");
   if(SymbolsToTest<1 || SymbolsToTest>10 ||
      BarsPerDataset<1000 || BarsPerDataset>10000)
   {
      Print("SMC_TEST FAIL | inputs out of range (symbols 1..10, bars 1000..10000)");
      return;
   }

   SMC_TestStructureClassification();
   SMC_TestOrderBlockMitigation();
   SMC_TestFVGMitigation();
   SMC_TestChartObjectLifecycle();
   SMC_TestMarketDataMatrix();

   PrintFormat("SMC_TEST SUMMARY | cases=%d failures=%d skipped_datasets=%d",
               SMC_VerificationCases,SMC_VerificationFailures,
               SMC_VerificationSkips);
}

// Derived from Smart Money Concepts
// Any redistribution must retain attribution and this license notice.
#property copyright " Smart Money Concepts"
#property version   "1.00"
#property indicator_chart_window
#include <SMC/SMC_Types.mqh>
#include <SMC/SMC_State.mqh>
#include <SMC/SMC_Config.mqh>
#include <SMC/SMC_Palette.mqh>
#include <SMC/SMC_OrderBlock.mqh>
#include <SMC/SMC_Structure.mqh>
#include <SMC/SMC_FVG.mqh>
#include <SMC/SMC_EqualLevels.mqh>
#include <SMC/SMC_Liquidity.mqh>
#include <SMC/SMC_Calculation.mqh>
#include <SMC/SMC_TimeframeAnalysis.mqh>
#property indicator_buffers 5
#property indicator_plots   1
#property indicator_type1   DRAW_COLOR_CANDLES
#property indicator_label1  "SMC trend candles"

input group "Smart Money Concepts"
input ENUM_SMC_MODE DisplayMode = SMC_HISTORICAL;
input bool ColorCandles = false;
input int MaxBarsToProcess = 2000;

input group "Chart Display"
input bool HideTradeHistoryMarkers = true;

input group "Market Bias"
input bool ShowMarketBias = true;
input bool ShowHigherTimeframeBias = true;

input group "Multi-Timeframe Bias"
input bool EnableBiasTimeframe1 = true;
input ENUM_TIMEFRAMES BiasTimeframe1 = PERIOD_H4;
input bool EnableBiasTimeframe2 = true;
input ENUM_TIMEFRAMES BiasTimeframe2 = PERIOD_D1;
input bool EnableBiasTimeframe3 = true;
input ENUM_TIMEFRAMES BiasTimeframe3 = PERIOD_W1;

input group "MTF Structure & Setup"
input bool ShowMTFStructureEvents = true;
input bool ShowMTFOrderBlocks = false;
input bool ShowMTFFairValueGaps = false;

input group "Real Time Internal Structure"
input bool ShowInternalStructure = true;
input ENUM_SMC_SHOW InternalBullishStructure = SMC_ALL;
input ENUM_SMC_SHOW InternalBearishStructure = SMC_ALL;
input bool InternalConfluenceFilter = false;
input ENUM_SMC_SIZE InternalLabelSize = SMC_TINY;

input group "Real Time Swing Structure"
input bool ShowSwingStructure = true;
input ENUM_SMC_SHOW SwingBullishStructure = SMC_ALL;
input ENUM_SMC_SHOW SwingBearishStructure = SMC_ALL;
input ENUM_SMC_SIZE SwingLabelSize = SMC_SMALL;
input bool ShowSwingPoints = false;
input int SwingLength = SMC_DEFAULT_SWING_LENGTH;
input bool ShowStrongWeakHighLow = false;

input group "Strong/Weak High-Low Display"
input bool ShowStrongHigh = true;
input bool ShowWeakHigh = true;
input bool ShowStrongLow = true;
input bool ShowWeakLow = true;

input group "Order Blocks"
input bool ShowInternalOrderBlocks = true;
input int InternalOrderBlocksToShow = SMC_DEFAULT_MAX_ORDER_BLOCKS_TO_SHOW;
input bool ShowSwingOrderBlocks = false;
input int SwingOrderBlocksToShow = SMC_DEFAULT_MAX_SWING_ORDER_BLOCKS_TO_SHOW;
input int OrderBlockExtend = SMC_DEFAULT_ORDER_BLOCK_EXTEND;
input ENUM_SMC_FILTER OrderBlockFilter = SMC_ATR;
input ENUM_SMC_MITIGATION OrderBlockMitigation = SMC_HIGH_LOW;

input group "EQH/EQL"
input bool ShowEqualHighsLows = true;
input int EqualHighLowConfirmationBars = SMC_DEFAULT_EQUAL_HIGH_LOW_BARS;
input double EqualHighLowThreshold = SMC_DEFAULT_EQUAL_HIGH_LOW_THRESHOLD;
input ENUM_SMC_SIZE EqualHighLowLabelSize = SMC_TINY;

input group "Fair Value Gaps"
input bool ShowFairValueGaps = false;
input bool FairValueGapAutoThreshold = false;
input int FairValueGapExtend = 1;
input int MaxFairValueGapsToShow = SMC_DEFAULT_MAX_FVG_COUNT;

input group "Previous Period Highs & Lows"
input bool ShowDailyLevels = false;
input ENUM_SMC_LINE_STYLE DailyLevelsStyle = SMC_SOLID;
input bool ShowWeeklyLevels = false;
input ENUM_SMC_LINE_STYLE WeeklyLevelsStyle = SMC_SOLID;
input bool ShowMonthlyLevels = false;
input ENUM_SMC_LINE_STYLE MonthlyLevelsStyle = SMC_SOLID;

input group "Premium & Discount Zones"
input bool ShowPremiumDiscountZones = false;

double CandleOpen[], CandleHigh[], CandleLow[], CandleClose[], CandleColorIndex[];
string ObjectPrefix = SMC_DEFAULT_OBJECT_PREFIX;
SMC_DrawConfig DrawConfig;
SMC_State State;
bool PreviousTradeHistoryVisibility = false;
bool TradeHistoryVisibilityCaptured = false;
bool TradeHistoryVisibilityChanged = false;
bool PreviousMouseMoveEvents = false;
bool MouseMoveEventsCaptured = false;
bool MouseMoveEventsChanged = false;
ENUM_TIMEFRAMES LastChartPeriod = PERIOD_CURRENT;
SMC_TimeframeBiasState TimeframeBiasStates[3];

#include <SMC/SMC_Draw.mqh>
#include <SMC/SMC_IndicatorFVG.mqh>
#include <SMC/SMC_IndicatorMTF.mqh>
#include <SMC/SMC_IndicatorRuntime.mqh>

int OnInit()
{
   if(SwingLength<10 || MaxBarsToProcess<MathMax(SwingLength,EqualHighLowConfirmationBars)+3 ||
      MaxBarsToProcess>10000 || EqualHighLowConfirmationBars<1 ||
      InternalOrderBlocksToShow<1 || InternalOrderBlocksToShow>20 ||
      SwingOrderBlocksToShow<1 || SwingOrderBlocksToShow>20 ||
      OrderBlockExtend<1 || OrderBlockExtend>1000 ||
      ((ShowFairValueGaps || ShowMTFFairValueGaps) &&
       (FairValueGapExtend<0 || MaxFairValueGapsToShow<1 ||
        MaxFairValueGapsToShow>100)) || EqualHighLowThreshold<0.0 ||
      EqualHighLowThreshold>0.5)
      return INIT_PARAMETERS_INCORRECT;
   TimeframeBiasStates[0].enabled=EnableBiasTimeframe1;
   TimeframeBiasStates[0].timeframe=
      (BiasTimeframe1==PERIOD_CURRENT ? _Period : BiasTimeframe1);
   TimeframeBiasStates[1].enabled=EnableBiasTimeframe2;
   TimeframeBiasStates[1].timeframe=
      (BiasTimeframe2==PERIOD_CURRENT ? _Period : BiasTimeframe2);
   TimeframeBiasStates[2].enabled=EnableBiasTimeframe3;
   TimeframeBiasStates[2].timeframe=
      (BiasTimeframe3==PERIOD_CURRENT ? _Period : BiasTimeframe3);
   for(int i=0;i<ArraySize(TimeframeBiasStates);i++)
   {
      if(TimeframeBiasStates[i].enabled &&
         (PeriodSeconds(TimeframeBiasStates[i].timeframe)<=0 ||
          TimeframeBiasStates[i].timeframe==PERIOD_CURRENT))
      {
         PrintFormat("SMC: invalid MTF bias timeframe in slot %d (%s).",
                     i+1,EnumToString(TimeframeBiasStates[i].timeframe));
         return INIT_PARAMETERS_INCORRECT;
      }
   }
   string legacyObjectPrefix="SC"+
                             IntegerToString((int)(ChartID()%100000))+"_";
   SMC_DeleteObjectsWithPrefix(legacyObjectPrefix);
   ObjectPrefix="SMC"+IntegerToString((long)ChartID())+"_";
   SMC_ClearObjects(ObjectPrefix);
   long tradeHistoryVisible=0;
   TradeHistoryVisibilityCaptured=
      ChartGetInteger(0,CHART_SHOW_TRADE_HISTORY,0,tradeHistoryVisible);
   if(!TradeHistoryVisibilityCaptured)
      PrintFormat("SMC: unable to read trade-history chart setting (error=%d).",
                  GetLastError());
   else
   {
      PreviousTradeHistoryVisibility=(tradeHistoryVisible!=0);
      if(HideTradeHistoryMarkers && PreviousTradeHistoryVisibility)
      {
         TradeHistoryVisibilityChanged=
            ChartSetInteger(0,CHART_SHOW_TRADE_HISTORY,false);
         if(!TradeHistoryVisibilityChanged)
            PrintFormat("SMC: unable to hide trade-history markers (error=%d).",
                        GetLastError());
      }
   }
   long mouseMoveEvents=0;
   MouseMoveEventsCaptured=
      ChartGetInteger(0,CHART_EVENT_MOUSE_MOVE,0,mouseMoveEvents);
   if(!MouseMoveEventsCaptured)
      PrintFormat("SMC: unable to read chart mouse-event setting (error=%d).",
                  GetLastError());
   else
   {
      PreviousMouseMoveEvents=(mouseMoveEvents!=0);
      if(!PreviousMouseMoveEvents)
      {
         MouseMoveEventsChanged=
            ChartSetInteger(0,CHART_EVENT_MOUSE_MOVE,true);
         if(!MouseMoveEventsChanged)
            PrintFormat("SMC: unable to enable mouse events for chart navigation (error=%d).",
                        GetLastError());
      }
   }
   ConfigureDrawing();
   LastChartPeriod=_Period;
   SetIndexBuffer(0,CandleOpen,INDICATOR_DATA);
   SetIndexBuffer(1,CandleHigh,INDICATOR_DATA);
   SetIndexBuffer(2,CandleLow,INDICATOR_DATA);
   SetIndexBuffer(3,CandleClose,INDICATOR_DATA);
   SetIndexBuffer(4,CandleColorIndex,INDICATOR_COLOR_INDEX);
   ArraySetAsSeries(CandleOpen,true);
   ArraySetAsSeries(CandleHigh,true);
   ArraySetAsSeries(CandleLow,true);
   ArraySetAsSeries(CandleClose,true);
   ArraySetAsSeries(CandleColorIndex,true);
   PlotIndexSetInteger(0,PLOT_COLOR_INDEXES,2);
   PlotIndexSetInteger(0,PLOT_LINE_COLOR,0,SMC_RGBColor(SMC_COLOR_BULLISH));
   PlotIndexSetInteger(0,PLOT_LINE_COLOR,1,SMC_RGBColor(SMC_COLOR_BEARISH));
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   IndicatorSetString(INDICATOR_SHORTNAME,"Smart Money Concepts");
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   SMC_ClearObjects(ObjectPrefix);
   if(TradeHistoryVisibilityCaptured && TradeHistoryVisibilityChanged &&
      PreviousTradeHistoryVisibility)
   {
      long tradeHistoryVisible=0;
      if(ChartGetInteger(0,CHART_SHOW_TRADE_HISTORY,0,tradeHistoryVisible) &&
         tradeHistoryVisible==0 &&
         !ChartSetInteger(0,CHART_SHOW_TRADE_HISTORY,true))
         PrintFormat("SMC: unable to restore trade-history visibility (error=%d).",
                     GetLastError());
   }
   if(MouseMoveEventsCaptured && MouseMoveEventsChanged &&
      !PreviousMouseMoveEvents)
   {
      long mouseMoveEvents=0;
      if(ChartGetInteger(0,CHART_EVENT_MOUSE_MOVE,0,mouseMoveEvents) &&
         mouseMoveEvents!=0 &&
         !ChartSetInteger(0,CHART_EVENT_MOUSE_MOVE,false))
         PrintFormat("SMC: unable to restore chart mouse-event setting (error=%d).",
                     GetLastError());
   }
}

void OnChartEvent(const int id,const long &lparam,const double &dparam,
                  const string &sparam)
{
   if(id==CHARTEVENT_MOUSE_MOVE && (StringToInteger(sparam)&1)!=0)
   {
      SMC_KeepHistoricalChartView();
      SMC_RenderPineDrawings();
      SMC_RenderZoneCanvas(ObjectPrefix);
   }
   if(id==CHARTEVENT_CHART_CHANGE)
   {
      SMC_KeepHistoricalChartView();
      SMC_RenderPineDrawings();
      SMC_RenderZoneCanvas(ObjectPrefix);
   }
}

bool ProcessNewBar(const int ratesTotal,const datetime &time[],const double &open[],
                   const double &high[],const double &low[],const double &close[])
{
   if(!SMC_AdvanceCalculationCaches(ratesTotal,MaxBarsToProcess,
                                   high,low,close,OrderBlockFilter,State))
      return false;

   StructureEvent structureEvents[2];
   int structureEventCount=0;
   SMC_DetectStructure(false,SwingLength,1,ratesTotal,time,open,high,low,close,
                       false,SwingLabelSize,State,
                       structureEvents,structureEventCount);
   SMC_StoreOrderBlocksFromStructureEvents(
      structureEvents,structureEventCount,time,State.ParsedHighs,
      State.ParsedLows,ratesTotal,1,true,State.OrderBlocks);
   RenderStructureEvents(structureEvents,structureEventCount);
   SMC_DetectStructure(true,SMC_DEFAULT_INTERNAL_STRUCTURE_SIZE,1,ratesTotal,time,open,high,low,close,
                       InternalConfluenceFilter,InternalLabelSize,State,
                       structureEvents,structureEventCount);
   SMC_StoreOrderBlocksFromStructureEvents(
      structureEvents,structureEventCount,time,State.ParsedHighs,
      State.ParsedLows,ratesTotal,1,true,State.OrderBlocks);
   RenderStructureEvents(structureEvents,structureEventCount);
   DetectEqualHighLow(EqualHighLowConfirmationBars,State.EqualLeg,
                      State.EqualHigh,State.EqualLow,1,ratesTotal,time,high,
                      low,State.AtrCache);
   if(ShowSwingPoints)
      SMC_DrawSwingLabels(DrawConfig,time,high,low,1,SwingLength,State.SwingHigh,State.SwingLow);

   SMC_UpdateTrailingLevels(true,time[0],high[0],low[0],
                            State);
   RemoveMitigatedOrderBlocks(high[1],low[1],close[1],time[1]);
   if(ColorCandles)
   {
      CandleOpen[1]=open[1];
      CandleHigh[1]=high[1];
      CandleLow[1]=low[1];
      CandleClose[1]=close[1];
      CandleColorIndex[1]=(State.InternalBias>0 ? 0 : 1);
      CandleOpen[0]=open[0];
      CandleHigh[0]=high[0];
      CandleLow[0]=low[0];
      CandleClose[0]=close[0];
      CandleColorIndex[0]=(State.InternalBias>0 ? 0 : 1);
   }
   else
   {
      CandleOpen[1]=EMPTY_VALUE;
      CandleHigh[1]=EMPTY_VALUE;
      CandleLow[1]=EMPTY_VALUE;
      CandleClose[1]=EMPTY_VALUE;
      CandleOpen[0]=EMPTY_VALUE;
      CandleHigh[0]=EMPTY_VALUE;
      CandleLow[0]=EMPTY_VALUE;
      CandleClose[0]=EMPTY_VALUE;
   }

   if(ShowFairValueGaps && RefreshCurrentFVGThreshold())
      UpdateFairValueGapsOnTick(time[0],high[0],low[0]);
   int periodSeconds=PeriodSeconds(_Period);
   if(periodSeconds<=0) periodSeconds=60;
   SMC_DrawOrderBlockObjects(DrawConfig,State.OrderBlocks,time[0],periodSeconds);
   if(ShowInternalStructure || ShowSwingStructure)
      SMC_RenderPresentStructures(DrawConfig,State.LatestStructures,State.PresentStructuresDirty);
   SMC_RenderPreviousLevels(DrawConfig,ratesTotal,time,high,low);
   SMC_DrawTrailingLevels(DrawConfig,State.TrailingTop,State.TrailingBottom,State.SwingBias,
                          time[0],periodSeconds);
   SMC_DrawPremiumDiscount(DrawConfig,State.TrailingTop,State.TrailingBottom,
                           State.TrailingAnchorTime,time[0],periodSeconds);
   SMC_UpdateTimeframeAnalysis();
   ChartRedraw(0);
   State.LastProcessedBar=time[0];
   State.LastRatesTotal=ratesTotal;
   return true;
}

void UpdateCurrentBar(const int ratesTotal,const datetime &time[],
                      const double &open[],const double &high[],
                      const double &low[],const double &close[])
{
   SMC_UpdateCurrentCalculationValues(high[0],low[0],close[1],ratesTotal,
                                      OrderBlockFilter,State);
   UpdateTrailingLevelsOnTick(time[0],high[0],low[0],PeriodSeconds(_Period));
   if(ColorCandles)
   {
      CandleOpen[0]=open[0];
      CandleHigh[0]=high[0];
      CandleLow[0]=low[0];
      CandleClose[0]=close[0];
      CandleColorIndex[0]=(State.InternalBias>0 ? 0 : 1);
   }
   else
   {
      CandleOpen[0]=EMPTY_VALUE;
      CandleHigh[0]=EMPTY_VALUE;
      CandleLow[0]=EMPTY_VALUE;
      CandleClose[0]=EMPTY_VALUE;
   }

   if(ShowFairValueGaps)
      UpdateFairValueGapsOnTick(time[0],high[0],low[0]);
   if(ShowInternalStructure || ShowSwingStructure)
      SMC_RenderPresentStructures(DrawConfig,State.LatestStructures,State.PresentStructuresDirty);
   SMC_UpdateTimeframeAnalysis();
}

bool RebuildHistoricalState(const int ratesTotal,const datetime &time[],
                            const double &open[],const double &high[],
                            const double &low[],const double &close[])
{
   if(!SMC_ResetState(State))
      return false;
   State.LastProcessedBar=time[0];
   State.LastRatesTotal=ratesTotal;
   SMC_ClearObjects(ObjectPrefix);

   int count=MathMin(ratesTotal,MaxBarsToProcess);
   for(int i=ratesTotal-1;i>=count;i--)
   {
      CandleOpen[i]=EMPTY_VALUE;
      CandleHigh[i]=EMPTY_VALUE;
      CandleLow[i]=EMPTY_VALUE;
      CandleClose[i]=EMPTY_VALUE;
      CandleColorIndex[i]=0;
   }
   int oldest=count-1;
   if(ArrayResize(State.AtrCache,count)!=count ||
      ArrayResize(State.MeanRangeCache,count)!=count ||
      ArrayResize(State.TrueRangeCache,count)!=count ||
      ArrayResize(State.ParsedHighs,count)!=count ||
      ArrayResize(State.ParsedLows,count)!=count)
   {
      PrintFormat("SMC: unable to allocate calculation caches (error=%d).",
                  GetLastError());
      return false;
   }
   ArraySetAsSeries(State.AtrCache,true);
   ArraySetAsSeries(State.MeanRangeCache,true);
   ArraySetAsSeries(State.TrueRangeCache,true);
   ArraySetAsSeries(State.ParsedHighs,true);
   ArraySetAsSeries(State.ParsedLows,true);
   for(int i=oldest;i>=0;i--)
   {
      CandleOpen[i]=EMPTY_VALUE; CandleHigh[i]=EMPTY_VALUE;
      CandleLow[i]=EMPTY_VALUE; CandleClose[i]=EMPTY_VALUE;
      CandleColorIndex[i]=0;
   }
   if(!SMC_InitializeCalculationCaches(ratesTotal,count,high,low,close,
                                       OrderBlockFilter,State))
   {
      Print("SMC: unable to initialize calculation caches.");
      return false;
   }

   for(int i=oldest-MathMax(SwingLength,EqualHighLowConfirmationBars)-1;i>=0;i--)
   {
      if(i+1>=ratesTotal) continue;
      SMC_UpdateTrailingLevels(true,time[i],high[i],low[i],
                               State);
      if(i>0)
      {
         StructureEvent structureEvents[2];
         int structureEventCount=0;
         SMC_DetectStructure(false,SwingLength,i,ratesTotal,time,open,high,low,
                             close,false,SwingLabelSize,State,
                             structureEvents,structureEventCount);
         SMC_StoreOrderBlocksFromStructureEvents(
            structureEvents,structureEventCount,time,State.ParsedHighs,
            State.ParsedLows,ratesTotal,i,true,State.OrderBlocks);
         RenderStructureEvents(structureEvents,structureEventCount);
         SMC_DetectStructure(true,SMC_DEFAULT_INTERNAL_STRUCTURE_SIZE,i,ratesTotal,time,open,high,low,close,
                             InternalConfluenceFilter,InternalLabelSize,State,
                             structureEvents,structureEventCount);
         SMC_StoreOrderBlocksFromStructureEvents(
            structureEvents,structureEventCount,time,State.ParsedHighs,
            State.ParsedLows,ratesTotal,i,true,State.OrderBlocks);
         RenderStructureEvents(structureEvents,structureEventCount);
         DetectEqualHighLow(EqualHighLowConfirmationBars,State.EqualLeg,
                            State.EqualHigh,State.EqualLow,i,ratesTotal,time,
                            high,low,State.AtrCache);
         if(ShowSwingPoints)
            SMC_DrawSwingLabels(DrawConfig,time,high,low,i,SwingLength,
                                State.SwingHigh,State.SwingLow);
         RemoveMitigatedOrderBlocks(high[i],low[i],close[i],time[i]);
      }
      if(ColorCandles)
      {
         CandleOpen[i]=open[i]; CandleHigh[i]=high[i];
         CandleLow[i]=low[i]; CandleClose[i]=close[i];
         CandleColorIndex[i]=(State.InternalBias>0 ? 0 : 1);
      }
   }

   int periodSeconds=PeriodSeconds(_Period);
   if(periodSeconds<=0) periodSeconds=60;
   if(ShowInternalStructure || ShowSwingStructure)
      SMC_RenderPresentStructures(DrawConfig,State.LatestStructures,State.PresentStructuresDirty);
   SMC_DrawOrderBlockObjects(DrawConfig,State.OrderBlocks,time[0],periodSeconds);
   if(ShowFairValueGaps)
      DrawFVGs();
   SMC_RenderPreviousLevels(DrawConfig,ratesTotal,time,high,low);
   SMC_DrawTrailingLevels(DrawConfig,State.TrailingTop,State.TrailingBottom,State.SwingBias,
                          time[0],periodSeconds);
   SMC_DrawPremiumDiscount(DrawConfig,State.TrailingTop,State.TrailingBottom,
                           State.TrailingAnchorTime,time[0],periodSeconds);
   SMC_UpdateTimeframeAnalysis(true);
   ChartRedraw(0);
   State.LastRatesTotal=ratesTotal;
   return true;
}

int OnCalculate(const int rates_total,const int prev_calculated,
                const datetime &time[],const double &open[],const double &high[],
                const double &low[],const double &close[],const long &tick_volume[],
                const long &volume[],const int &spread[])
{
   if(rates_total<MathMax(SwingLength,EqualHighLowConfirmationBars)+3)
      return 0;
   ArraySetAsSeries(time,true);
   ArraySetAsSeries(open,true);
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true);
   ArraySetAsSeries(close,true);
   if(LastChartPeriod!=_Period)
   {
      LastChartPeriod=_Period;
      ConfigureDrawing();
      if(!RebuildHistoricalState(rates_total,time,open,high,low,close))
         return 0;
      SMC_RenderPineDrawings();
      SMC_RenderZoneCanvas(ObjectPrefix);
      return rates_total;
   }
   if(prev_calculated>0 && State.LastProcessedBar>0 &&
      time[0]>State.LastProcessedBar)
   {
      if(ProcessNewBar(rates_total,time,open,high,low,close))
      {
         SMC_RenderPineDrawings();
         SMC_RenderZoneCanvas(ObjectPrefix);
         return rates_total;
      }
   }
   if(prev_calculated>0 && State.LastProcessedBar==time[0])
   {
      UpdateCurrentBar(rates_total,time,open,high,low,close);
      SMC_RenderPineDrawings();
      SMC_RenderZoneCanvas(ObjectPrefix);
      return rates_total;
   }
   if(!RebuildHistoricalState(rates_total,time,open,high,low,close))
      return 0;
   SMC_RenderPineDrawings();
   SMC_RenderZoneCanvas(ObjectPrefix);
   return rates_total;
}

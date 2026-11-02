// Unit tests for SMC EQH/EQL liquidity sweep rules.
#include <SMC\SMC_Liquidity.mqh>

datetime TestTime(const long value)
  {
   return((datetime)value);
  }

void SetLiquidityPool(SMC_LiquidityState &state,const bool high,
                     const double firstPrice,const double secondPrice,
                     const datetime confirmedAt)
  {
   EqualLevelEvent equalLevel;
   ZeroMemory(equalLevel);
   equalLevel.valid=true;
   equalLevel.high=high;
   equalLevel.firstTime=TestTime((long)confirmedAt-20);
   equalLevel.secondTime=TestTime((long)confirmedAt-10);
   equalLevel.firstPrice=firstPrice;
   equalLevel.secondPrice=secondPrice;
   SMC_UpdateLiquidityFromEqualLevel(equalLevel,confirmedAt,state);
  }

bool TestEqualHighSweep()
  {
   SMC_LiquidityState state;
   ZeroMemory(state);
   SetLiquidityPool(state,true,100.0,102.0,TestTime(100));

   SMC_LiquiditySweepEvent highEvent,lowEvent;
   SMC_DetectLiquiditySweeps(TestTime(101),103.0,99.0,101.0,state,
                             highEvent,lowEvent);
   return(highEvent.valid && highEvent.high &&
          highEvent.poolPrice==102.0 && highEvent.wickExtreme==103.0 &&
          highEvent.close==101.0 && highEvent.time==TestTime(101) &&
          !lowEvent.valid && state.equalHigh.swept &&
          state.equalHigh.sweepTime==TestTime(101));
  }

bool TestEqualLowSweep()
  {
   SMC_LiquidityState state;
   ZeroMemory(state);
   SetLiquidityPool(state,false,98.0,100.0,TestTime(100));

   SMC_LiquiditySweepEvent highEvent,lowEvent;
   SMC_DetectLiquiditySweeps(TestTime(101),101.0,97.0,99.0,state,
                             highEvent,lowEvent);
   return(lowEvent.valid && !lowEvent.high &&
          lowEvent.poolPrice==98.0 && lowEvent.wickExtreme==97.0 &&
          lowEvent.close==99.0 && lowEvent.time==TestTime(101) &&
          !highEvent.valid && state.equalLow.swept &&
          state.equalLow.sweepTime==TestTime(101));
  }

bool TestEqualHighBoundaries()
  {
   SMC_LiquidityState state;
   ZeroMemory(state);
   SetLiquidityPool(state,true,100.0,102.0,TestTime(100));

   SMC_LiquiditySweepEvent event;
   if(SMC_DetectLiquiditySweepForLevel(state.equalHigh,true,TestTime(101),
                                       102.0,99.0,101.0,event) ||
      event.valid || state.equalHigh.swept || state.equalHigh.invalidated)
      return(false);
   if(SMC_DetectLiquiditySweepForLevel(state.equalHigh,true,TestTime(102),
                                       103.0,99.0,102.0,event) ||
      event.valid || state.equalHigh.swept || state.equalHigh.invalidated)
      return(false);
   return(true);
  }

bool TestPoolConfirmationBarIsIgnored()
  {
   SMC_LiquidityState state;
   ZeroMemory(state);
   SetLiquidityPool(state,true,100.0,102.0,TestTime(100));

   SMC_LiquiditySweepEvent event;
   return(!SMC_DetectLiquiditySweepForLevel(
             state.equalHigh,true,TestTime(100),103.0,99.0,101.0,event) &&
          !event.valid && !state.equalHigh.swept &&
          !state.equalHigh.invalidated);
  }

bool TestBreakoutInvalidatesPool()
  {
   SMC_LiquidityState state;
   ZeroMemory(state);
   SetLiquidityPool(state,true,100.0,102.0,TestTime(100));

   SMC_LiquiditySweepEvent event;
   if(SMC_DetectLiquiditySweepForLevel(state.equalHigh,true,TestTime(101),
                                       104.0,101.0,103.0,event) ||
      event.valid || !state.equalHigh.invalidated)
      return(false);
   if(SMC_DetectLiquiditySweepForLevel(state.equalHigh,true,TestTime(102),
                                       105.0,99.0,101.0,event))
      return(false);
   return(!event.valid && !state.equalHigh.swept);
  }

bool TestPoolSweepsOnlyOnce()
  {
   SMC_LiquidityState state;
   ZeroMemory(state);
   SetLiquidityPool(state,true,100.0,102.0,TestTime(100));

   SMC_LiquiditySweepEvent event;
   if(!SMC_DetectLiquiditySweepForLevel(state.equalHigh,true,TestTime(101),
                                        103.0,99.0,101.0,event) ||
      !event.valid)
      return(false);
   if(SMC_DetectLiquiditySweepForLevel(state.equalHigh,true,TestTime(102),
                                       104.0,99.0,101.0,event))
      return(false);
   return(!event.valid && state.equalHigh.swept);
  }

bool TestHighAndLowPoolsAreIndependent()
  {
   SMC_LiquidityState state;
   ZeroMemory(state);
   SetLiquidityPool(state,true,104.0,105.0,TestTime(100));
   SetLiquidityPool(state,false,95.0,96.0,TestTime(100));

   SMC_LiquiditySweepEvent highEvent,lowEvent;
   SMC_DetectLiquiditySweeps(TestTime(101),106.0,94.0,100.0,state,
                             highEvent,lowEvent);
   return(highEvent.valid && highEvent.high &&
          highEvent.poolPrice==105.0 && lowEvent.valid && !lowEvent.high &&
          lowEvent.poolPrice==95.0 && state.equalHigh.swept &&
          state.equalLow.swept);
  }

bool TestReplacingPoolResetsLifecycle()
  {
   SMC_LiquidityState state;
   ZeroMemory(state);
   SetLiquidityPool(state,true,100.0,102.0,TestTime(100));
   state.equalHigh.swept=true;
   state.equalHigh.sweepTime=TestTime(101);
   state.equalHigh.invalidated=true;

   SetLiquidityPool(state,true,105.0,106.0,TestTime(200));
   return(state.equalHigh.valid && !state.equalHigh.swept &&
          !state.equalHigh.invalidated && state.equalHigh.sweepTime==0 &&
          state.equalHigh.confirmedAt==TestTime(200) &&
          SMC_LiquidityPoolPrice(state.equalHigh,true)==106.0);
  }

void RecordTest(const string name,const bool passed,
                int &testsPerformed,int &testsPassed)
  {
   testsPerformed++;
   if(passed)
     {
      testsPassed++;
      PrintFormat("PASS: %s",name);
     }
   else
      PrintFormat("FAIL: %s",name);
  }

void OnStart()
  {
   int testsPerformed=0;
   int testsPassed=0;

   RecordTest("EQH sweep uses the outer high and closes back below",
              TestEqualHighSweep(),testsPerformed,testsPassed);
   RecordTest("EQL sweep uses the outer low and closes back above",
              TestEqualLowSweep(),testsPerformed,testsPassed);
   RecordTest("Touch and close exactly at the pool are not sweeps",
              TestEqualHighBoundaries(),testsPerformed,testsPassed);
   RecordTest("Pool confirmation bar cannot sweep its own pool",
              TestPoolConfirmationBarIsIgnored(),testsPerformed,testsPassed);
   RecordTest("Close beyond pool invalidates it without a sweep",
              TestBreakoutInvalidatesPool(),testsPerformed,testsPassed);
   RecordTest("A pool emits at most one sweep",
              TestPoolSweepsOnlyOnce(),testsPerformed,testsPassed);
   RecordTest("EQH and EQL pools are evaluated independently",
              TestHighAndLowPoolsAreIndependent(),testsPerformed,testsPassed);
   RecordTest("A replacement pool resets previous lifecycle flags",
              TestReplacingPoolResetsLifecycle(),testsPerformed,testsPassed);

   PrintFormat("Liquidity sweep tests: %d/%d passed",
               testsPassed,testsPerformed);
  }

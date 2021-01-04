// CroneEngine_BandSaw
// bandpass filtered sawtooth wave with arbirary envelope:
//    based on example given in Eli Fieldsteel's SuperCollider composition tutorial: https://youtu.be/lGs7JOOVjag
// voice management:
//    based on Mark Wheeler's (@markeats) MollyThePoly engine: https://github.com/markwheeler/molly_the_poly

//////////////////////////////////////
// notes and todo list:
//    notes: 
//      for the values received by set_cfScalars in flora.lua,
//        rather than passing the "actual" value in the cf_scalars array,
//        the position in the array is being sent. 
//      note frequency is limited to 0.2 to prevent loud noises 
//        see https://doc.sccode.org/Classes/BPF.html for details

//    todo list: 
//      figure out why rqmin can be set higher than rqmax and still work
//      remove unused variables/functions e.g. for gain, pan, etc.
//////////////////////////////////////

Engine_BandSaw : CroneEngine {
	classvar maxNumVoices = 10;
	var voiceGroup;
	var voiceList;
	var lastFreq = 0;

  var amp=1;
  var gain=1;
  var pan = 0;
  var maxsegments = 20;
  var levels, times, curves;
  var detune=0.2;
  var cfhzmin=0.1;
  var cfhzmax=0.3;
  var rqmin=0.005;
  var rqmax=0.008;
  var lsf=200;
  var ldb=0;
  var frequencies;
  var numFrequencies = 6;
  var cfScalars;
  var numCFScalars;
  var bandsaw;
  
  *new { arg context, doneCallback;
	  ^super.new(context, doneCallback);
  }
  
  alloc {
  
		voiceGroup = Group.new(context.xg);
		voiceList = List.new();
    
    // default set of sawtoothwave frequencies
    frequencies = [1/8,1/4,1/2,2/3,1,4/3,2,5/2,3,4];

    //bandpass filtered sawtooth wave
  	bandsaw = SynthDef(\BandSaw, {
  		arg c1=1, c2=(-1),
  		freq=1/2, 
  		detune=0.2, pan=0, cfhzmin=0.1,cfhzmax=0.3,
  		cfmin=500, cfmax=2000, rqmin=0.005, rqmax=0.008,
  		lsf=200, ldb=0, amp=1, out=0;
  		
  		var sig, env, envctl;

      env = Env.newClear(20);
      envctl = \env.kr(env.asArray);
      
  		sig = Saw.ar(freq * {LFNoise1.kr(0.5,detune).midiratio}!2);
  		sig = BPF.ar(
  			sig,
  			cfmin,
  			{LFNoise1.kr(0.1).exprange(rqmin,rqmax)}!2
  		);
      
      /*
  		sig = BPF.ar(
  			sig,
  			{LFNoise1.kr(
  				LFNoise1.kr(4).exprange(cfhzmin,cfhzmax)
  			).exprange(cfmin,cfmax)}!2,
  			{LFNoise1.kr(0.1).exprange(rqmin,rqmax)}!2
  		);
  		*/
  		
  		//Low Shelf Filter
  		sig = BLowShelf.ar(sig, lsf, 0.5, ldb);
  		sig = Balance2.ar(sig[0], sig[1], pan);
  		sig = sig * amp * EnvGen.kr(envctl, doneAction:2);
  		Out.ar(out, sig);
  	}).add;
      

    this.addCommand("set_numCFScalars", "f", { arg msg;
      numCFScalars = msg[1];
    });

    //see note above regarding this command
    this.addCommand("set_cfScalars", "ffff", { arg msg;
			var cfScalarsMap;
			cfScalarsMap = [0.5,1,2,4];
			cfScalars = Array.new(numCFScalars);
			for (0, numCFScalars-1, { arg i; 
			  var val = msg[i+1];
			  cfScalars.insert(i,cfScalarsMap[val-1]);
		  }); 
    });
    
    this.addCommand("set_numFrequencies", "f", { arg msg;
      numFrequencies = msg[1];
    });

    this.addCommand("set_frequencies", "ffffff", { arg msg;
			frequencies = Array.new(numFrequencies);
			for (0, numFrequencies-1, { arg i; 
			  var val = msg[i+1];
			  frequencies.insert(i,val);
		  }); 
    });

	  this.addCommand(\note_on, "ff", { arg msg;
        var voiceToRemove, newVoice;
  			var freqStream = Prand(frequencies,1).asStream.next;
  			var id = msg[1];
  			var val = msg[2];
        var cfval = val;
  			var c1=1, c2=(-1);
        var cfScalarStream = Prand(cfScalars,1).asStream.next;
        var env = Array.new(~numSegs-1);

  			("freqStream" + freqStream).postln;
  			if (freqStream < 0.2) {
  			  freqStream = 0.2;
  			  ("frequency too low!!!!").postln;
			  };
        
        for (0, ~numSegs-1, { arg i;
      	  var xycSegment = Array.new(3);
        	xycSegment.insert(0, times[i]);
        	xycSegment.insert(1, levels[i]);
        	xycSegment.insert(2, curves[i]);
        	env.insert(i,xycSegment);
    	  });

  			// Remove voice if ID matches or there are too many
  			voiceToRemove = voiceList.detect{arg item; item.id == id};
  			if(voiceToRemove.isNil && (voiceList.size >= maxNumVoices), {
  				voiceToRemove = voiceList.detect{arg v; v.gate == 0};
  				if(voiceToRemove.isNil, {
  					voiceToRemove = voiceList.last;
  				});
  			});
  			if(voiceToRemove.notNil, {
  				voiceToRemove.theSynth.set(\gate, 0);
  				voiceToRemove.theSynth.set(\killGate, 0);
  				voiceList.remove(voiceToRemove);
  			});
  			
    	  env = Env.xyc(env);

			  // Add new voice 
			  context.server.makeBundle(nil, {
  				newVoice = (id: id, theSynth: Synth("BandSaw",
  		    [
  		      \amp, amp,
  		      \env, env,
  		      \freq, freqStream,
  		    	\detune, Pwhite(0,0.1).asStream.next,
  		    	\cfhzmin, cfhzmin,
  		    	\cfhzmax, cfhzmax,
    		    \rqmin, rqmin, //0.005, //0.0001, 
  	        \rqmax, rqmax, //0.008, //1, 
    		    \cfmin, cfval * cfScalarStream, 
//    		    \cfmax, cfval * cfScalarStream,
//    		    \cfmax, cfval * cfScalarStream * Pwhite(1.008,1.025).asStream.next,
    		    \lsf, lsf,
    		    \ldb, ldb
		      ], 
		      target: voiceGroup).onFree({ 
		        voiceList.remove(newVoice); 
	        }));
        
				voiceList.addFirst(newVoice);
				lastFreq = freqStream;
      });
		});
		
    this.addCommand("set_numSegs", "f", { arg msg;
    	~numSegs = msg[1];
    });
    
    this.addCommand("set_levels", "ffffffffffffffffffff", { arg msg;
			levels = Array.new(~numSegs);
			for (0, ~numSegs-1, { arg i;
			  var val = msg[i+1];
			  levels.insert(i,val);
		  }); 
    });
    
    this.addCommand("set_times", "ffffffffffffffffffff", { arg msg;
			times = Array.new(~numSegs);
			for (0, ~numSegs-1, { arg i; 
			  var val = msg[i+1];
			  times.insert(i,val);
		  }); 
    });
    
    this.addCommand("set_curves", "ffffffffffffffffffff", { arg msg;
			curves = Array.new(~numSegs);
			for (0, ~numSegs-1, { arg i;
			  var val = msg[i+1];
			  curves.insert(i,val);
		  }); 
    });

		this.addCommand("cfhzmin", "f", { arg msg;
			cfhzmin = msg[1];
		});

		this.addCommand("cfhzmax", "f", { arg msg;
			cfhzmax = msg[1];
		});

		this.addCommand("rqmin", "f", { arg msg;
			rqmin = msg[1];
		});

		this.addCommand("rqmax", "f", { arg msg;
			rqmax = msg[1];
		});
    
    this.addCommand("lsf", "f", { arg msg;
			lsf = msg[1];
		});
		
		this.addCommand("ldb", "f", { arg msg;
			ldb = msg[1];
		});
		
		this.addCommand("amp", "f", { arg msg;
			amp = msg[1];
		});

		this.addCommand("gain", "f", { arg msg;
			gain = msg[1];
		});
		
		this.addCommand("pan", "f", { arg msg;
		  pan = msg[1];
		});
	}

	free {
		voiceGroup.free;
	  
	  //("free").postln;
		//lfos.free;
		//synthVoice.free;
		//reverb.free;
		//replyFunc.free;
	}

}


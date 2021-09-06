// CroneEngine_BandSaw
// bandpass filtered sawtooth wave with arbirary envelope:
//    based on example given in Eli Fieldsteel's SuperCollider composition tutorial: https://youtu.be/lGs7JOOVjag
// voice management:
//    based on Mark Wheeler's (@markeats) MollyThePoly engine: https://github.com/markwheeler/molly_the_poly

//////////////////////////////////////
// notes and todo list:
//    notes: 
//      note frequency is limited to 0.2 to prevent loud noises 
//        see https://doc.sccode.org/Classes/BPF.html for details
//
//    todo list: 
//      figure out why rqmin can be set higher than rqmax and still work
//      remove unused variables/functions e.g. for gain, pan, etc.
//////////////////////////////////////

Engine_BandSaw : CroneEngine {
  classvar maxNumVoices = 10;
  var voiceGroup;
  var voiceList;
  var amp=1;
  var gain=1;
  var pan = 0;
  var maxsegments = 20;
  var env_levels, env_times, env_curves;
  var detune=0.2;
  var cfhzmin=0.1;
  var cfhzmax=0.3;
  var rqmin=0.005;
  var rqmax=0.008;
  var lsf=200;
  var ldb=0;
  var frequency = 1;
  var bandsaw;
  
  var wobble_rpm=33;
  var wobble_amp=0.05; 
  var wobble_exp=39;
  var flutter_amp=0.03;
  var flutter_fixedfreq=6;
  var flutter_variationfreq=2;  
  var effect_pitchshift=0.5,pitchshift_note1=1,pitchshift_note2=3,pitchshift_note3=5;
  *new { arg context, doneCallback;
    ^super.new(context, doneCallback);
  }
  
  alloc {
  
    voiceGroup = Group.new(context.xg);
    voiceList = List.new();
    
    // default set of sawtoothwave frequencies
    //frequencies = [1/8,1/4,1/2,2/3,1,4/3,2,5/2,3,4];

    //bandpass filtered sawtooth wave
    bandsaw = SynthDef(\BandSaw, {
      arg c1=1, c2=(-1),
      freq=1/2, 
      detune=0.2, pan=0, cfhzmin=0.1,cfhzmax=0.3,
      cf=500, rqmin=0.005, rqmax=0.008,
//    cfmin=500, cfmax=2000, rqmin=0.005, rqmax=0.008,
      lsf=200, ldb=0, amp=1, out=0,
      wobble_rpm=33, wobble_amp=0.05, wobble_exp=39, flutter_amp=0.03, flutter_fixedfreq=6, flutter_variationfreq=2,
      effect_pitchshift=0.5, pitchshift_midi_offset=0, 
      pitchshift_note1=1,pitchshift_note2=3,pitchshift_note3=5;
  		
      var sig, env, envctl;

      var signed_wobble = wobble_amp*(SinOsc.kr(wobble_rpm/60)**wobble_exp);
      var wow = Select.kr(signed_wobble > 0, signed_wobble, 0);
      var flutter = flutter_amp*SinOsc.kr(flutter_fixedfreq+LFNoise2.kr(flutter_variationfreq));
      var combined_defects = 1 + wow + flutter;
      var pshift_freq, trig,hasFreq,pitchshift_notes;

      env = Env.newClear(maxsegments);
      envctl = \env.kr(env.asArray);
      
      //sig = Saw.ar(freq * {LFNoise1.kr(0.5,detune).midiratio}!2);
      sig = Saw.ar(freq);
      
      sig = BPF.ar(
        sig,
        cf * combined_defects,
        {LFNoise1.kr(0.1).exprange(rqmin,rqmax)}!2
      );
      
      //Low Shelf Filter
      sig = BLowShelf.ar(sig, lsf, 0.5, ldb);


      // Pitchshifting
      # pshift_freq, hasFreq = Tartini.kr(sig);
      pshift_freq = Clip.ar(freq, 40.midicps, 70.midicps);
      trig = Impulse.ar(4);
      pitchshift_notes = Dseq([pitchshift_note1,pitchshift_note2,pitchshift_note3], inf);
      sig = (sig*(1-effect_pitchshift))+(effect_pitchshift*PitchShift.ar(
        sig,
        0.1,
        // ((Demand.ar(trig, 0, notes)).midicps / freq),
        // ((Demand.ar(trig, 0, notes) + (54 * combined_defects)).midicps / freq),
        ((Demand.ar(trig, 0, pitchshift_notes) + (freq.cpsmidi + pitchshift_midi_offset)).midicps / freq) * combined_defects,
        0,
        0.01
      ));

      sig = Balance2.ar(sig[0], sig[1], pan);
      sig = sig * amp * EnvGen.kr(envctl, doneAction:2);
      
      Out.ar(out, sig);
    }).add;
      
    ////////////////////////
    // moved code into lua
    ///////////////////////
    /*
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
    */
    
    this.addCommand("set_frequency", "f", { arg msg;
      frequency = msg[1];
    });
    
    
    this.addCommand(\note_on, "fff", { arg msg;
      var voiceToRemove, newVoice;
      //var freqStream = Prand(frequencies,1).asStream.next;
      var id = msg[1];
      var cfval = msg[2];
      var frequency = msg[3];
      //var cfval = val;
      var c1=1, c2=(-1);
      //var cfScalarStream = Prand(cfScalars,1).asStream.next;
      var env = Array.new(~numSegs-1);
      if (frequency < 0.2) {
        frequency = 0.2;
        ("frequency too low!!!!").postln;
      };
        
      for (0, ~numSegs-1, { arg i;
        var xycSegment = Array.new(3);
        xycSegment.insert(0, env_times[i]);
        xycSegment.insert(1, env_levels[i]);
        xycSegment.insert(2, env_curves[i]);
        env.insert(i,xycSegment);
      });

      // Remove voice if ID matches or there are too many
      voiceToRemove = voiceList.detect{arg item; item.id == id};
      //(voiceList.size >= maxNumVoices).postln;
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
            //\freq, freqStream,
            \freq, frequency,
            \detune, Pwhite(0,0.1).asStream.next,
            \cfhzmin, cfhzmin,
            \cfhzmax, cfhzmax,
            \rqmin, rqmin, //0.005, //0.0001, 
            \rqmax, rqmax, //0.008, //1, 
            \cf, cfval,
//          \cfmin, cfval * cfScalarStream, 
//
//          \cfmax, cfval * cfScalarStream,
//          \cfmax, cfval * cfScalarStream * Pwhite(1.008,1.025).asStream.next,
            \lsf, lsf,
            \ldb, ldb,
            \wobble_rpm, wobble_rpm,
            \wobble_amp, wobble_amp,
            \wobble_exp, wobble_exp, // best an odd power, higher values produce sharper, smaller peak
            \flutter_amp, flutter_amp,
            \flutter_fixedfreq, flutter_fixedfreq,
            \flutter_variationfreq, flutter_variationfreq,
            \effect_pitchshift,effect_pitchshift,
            \pitchshift_note1,pitchshift_note1,
            \pitchshift_note2,pitchshift_note2,
            \pitchshift_note3,pitchshift_note3,
          ], 
  	      
  	      target: voiceGroup).onFree({ 
            //("free").postln;
            voiceList.remove(newVoice); 
          })
        );
        
        voiceList.addFirst(newVoice);
      });
    });
		
		
		
    this.addCommand("set_numSegs", "f", { arg msg;
    	~numSegs = msg[1];
    });
    
    this.addCommand("set_env_levels", "ffffffffffffffffffff", { arg msg;
      env_levels = Array.new(~numSegs);
      for (0, ~numSegs-1, { arg i;
        var val = msg[i+1];
        env_levels.insert(i,val);
      }); 
    });
    
    this.addCommand("set_env_times", "ffffffffffffffffffff", { arg msg;
      env_times = Array.new(~numSegs);
      for (0, ~numSegs-1, { arg i; 
        var val = msg[i+1];
        env_times.insert(i,val);
      }); 
    });
    
    this.addCommand("set_env_curves", "ffffffffffffffffffff", { arg msg;
      env_curves = Array.new(~numSegs);
      for (0, ~numSegs-1, { arg i;
        var val = msg[i+1];
        env_curves.insert(i,val);
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
    
    // wow and flutter commands
    this.addCommand("wobble_rpm", "f", { arg msg;
      wobble_rpm = msg[1];
    });
    
    this.addCommand("wobble_amp", "f", { arg msg;
      wobble_amp = msg[1];
    });
    
    this.addCommand("wobble_exp", "f", { arg msg;
      wobble_exp = msg[1];
    });
    
    this.addCommand("flutter_amp", "f", { arg msg;
      flutter_amp = msg[1];
    });
    
    this.addCommand("flutter_fixedfreq", "f", { arg msg;
      flutter_fixedfreq = msg[1];
    });
    
    this.addCommand("flutter_variationfreq", "f", { arg msg;
      flutter_variationfreq = msg[1];
    });


    this.addCommand("effect_pitchshift", "f", { arg msg;
      msg[1].postln;
      effect_pitchshift = msg[1];
    });

    this.addCommand("pitchshift_note1", "f", { arg msg;
      msg[1].postln;
      pitchshift_note1 = msg[1];
    });

    this.addCommand("pitchshift_note2", "f", { arg msg;
      msg[1].postln;
      pitchshift_note2 = msg[1];
    });

    this.addCommand("pitchshift_note3", "f", { arg msg;
      msg[1].postln;
      pitchshift_note3 = msg[1];
    });

  }

  free {
    voiceGroup.free;
	  //replyFunc.free;
  }
}

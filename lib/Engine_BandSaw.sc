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

  var maxCPU = 50;
  
  var voiceGroup;
  var <voices;
  var effects;
  var effectsBus;
  var controlBus;

  var amp=1;
  var gain=1;
  var pan = 0;
  var maxsegments = 20;
  var num_env_segments, env_levels, env_times, env_curves;
  var detune=0.2;
  var cfhzmin=0.1;
  var cfhzmax=0.3;
  var rqmin=0.005;
  var rqmax=0.008;
  var lsf=200;
  var ldb=0;
  var frequency = 1;
  
  var wobble_rpm=33;
  var wobble_amp=0.05; 
  var wobble_exp=39;
  var flutter_amp=0.03;
  var flutter_fixedfreq=6;
  var flutter_variationfreq=2;  
  var effect_pitchshift=0.5, pitchshift_offset=0, pitchshift_note1=1, pitchshift_note2=3, pitchshift_note3=5;
  // var notes, scale_length=24, scale;
  var scale_length=24;
  var trigger_frequency=1, base_note=0;

  *new { arg context, doneCallback;
    ^super.new(context, doneCallback);
  }
  
  alloc {

    // fork { 
    //   loop { 
    //     if ((context.server.peakCPU > maxCPU) && (context.server.avgCPU > maxCPU)){
    //       ["peakCPU/avgCPU not ok, maxCPU limit exceeded", context.server.peakCPU].postln; 
    //     };
    //     0.01.wait; 
    //   } 
    // };

    // voiceGroup = Group.new(context.xg);
    voiceGroup = ParGroup.head(context.xg);
    voices = Array.new();
    
    effectsBus = Bus.audio(context.server, 1);

    SynthDef(\BandSaw, {
      // arg out, effectsBus,
      arg out,
      freq=1/2, 
      detune=0.2, pan=0, cfhzmin=0.1,cfhzmax=0.3,
      cf=500, rqmin=0.005, rqmax=0.008,
      lsf=200, ldb=0, amp=1, 
      wobble_rpm=33, wobble_amp=0.05, wobble_exp=39, flutter_amp=0.03, flutter_fixedfreq=6, flutter_variationfreq=2;
  		
      var sig, env, envctl;
      var signed_wobble = wobble_amp*(SinOsc.kr(wobble_rpm/60)**wobble_exp);
      var wow = Select.kr(signed_wobble > 0, signed_wobble, 0);
      var flutter = flutter_amp*SinOsc.kr(flutter_fixedfreq+LFNoise2.kr(flutter_variationfreq));
      var combined_defects = 1 + wow + flutter;
      var checkCPU;

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
      sig = Balance2.ar(sig[0], sig[1], pan);
      sig = sig * amp * EnvGen.kr(envctl, doneAction:2);
      Out.ar(out, sig);
    }).add;
      

    //effects
    effects = SynthDef(\effects, {

      //pitschshift
      arg in, out, trigger_frequency=1, effect_pitchshift=0.5, pitchshift_offset=0, base_note = 24,
      pitchshift_note1=1,pitchshift_note2=3,pitchshift_note3=5,
      scale, quantize=1, grain_size=0.1, time_dispersion=0.01;
      
      var pitchshift_notes, trigger;
      var sig = In.ar(in, 2), pitch_ratio;
      
      // quantize notes::: WORK IN PROGRESS
      // pitchshift_note1 = (quantize * (DegreeToKey.kr(scale,pitchshift_note1) - base_note.cpsmidi))+((1-quantize)*(pitchshift_note1));
      // pitchshift_note2 = (quantize * (DegreeToKey.kr(scale,pitchshift_note2) - base_note.cpsmidi))+((1-quantize)*(pitchshift_note2));
      // pitchshift_note3 = (quantize * (DegreeToKey.kr(scale,pitchshift_note3) - base_note.cpsmidi))+((1-quantize)*(pitchshift_note3));

      trigger = Impulse.ar(trigger_frequency);
      pitchshift_notes = Dseq([pitchshift_note1,pitchshift_note2,pitchshift_note3], inf);
      pitch_ratio = ((Demand.ar(trigger, 0, pitchshift_notes) + (base_note.cpsmidi + pitchshift_offset)).midicps / base_note);
      sig = (sig*(1-effect_pitchshift))+(effect_pitchshift*PitchShift.ar(
        sig,
        grain_size,
        pitch_ratio,
        0,
        time_dispersion
      ));

      Out.ar(out, sig);
    }).play(target: context.xg, args: [\in, effectsBus, \out, context.out_b], addAction: \addToTail);



    context.server.sync;

    this.addCommand("set_frequency", "f", { arg msg;
      frequency = msg[1];
    });
    
    
    this.addCommand(\note_on, "fff", { arg msg;
      var voiceToRemove, newVoice;
      var id = msg[1];
      var cfval = msg[2];
      var frequency = msg[3];
      var env = Array.new(num_env_segments-1);

      if (frequency < 0.2) {
        frequency = 0.2;
        ("frequency too low!!!!").postln;
      };

      // Remove voice if ID matches or there are too many
      voiceToRemove = voices.detect{arg item; item.id == id};
      if(voiceToRemove.isNil && (voices.size >= maxNumVoices), {
        voiceToRemove = voices.detect{arg v; v.gate == 0};
      	if(voiceToRemove.isNil, {
      	  voiceToRemove = voices.last;
      	});
      });
      
      if(voiceToRemove.notNil, {
        voiceToRemove.theSynth.set(\gate, 0);
        voiceToRemove.theSynth.set(\killGate, 0);
        voices.remove(voiceToRemove);
      });

      // set the envelope
      for (0, num_env_segments-1, { arg i;
        var xycSegment = Array.new(3);
        xycSegment.insert(0, env_times[i]);
        xycSegment.insert(1, env_levels[i]);
        xycSegment.insert(2, env_curves[i]);
        env.insert(i,xycSegment);
      });

      env = Env.xyc(env);

      // set the effects's trigger frequency and base note
      effects.set(\trigger_frequency, frequency);
      // ["cfval.cpsmidi",cfval.cpsmidi].postln;
      effects.set(\base_note, cfval.cpsmidi);

      // Add new voice 
      context.server.makeBundle(nil, {
        newVoice = (id: id, theSynth: Synth("BandSaw",
          [
            \out, effectsBus,
            \amp, amp,
            \env, env,
            \freq, frequency,
            \detune, Pwhite(0,0.1).asStream.next,
            \cfhzmin, cfhzmin,
            \cfhzmax, cfhzmax,
            \rqmin, rqmin, 
            \rqmax, rqmax, 
            \cf, cfval,
            \lsf, lsf,
            \ldb, ldb,
            \wobble_rpm, wobble_rpm,
            \wobble_amp, wobble_amp,
            \wobble_exp, wobble_exp, // best an odd power, higher values produce sharper, smaller peak
            \flutter_amp, flutter_amp,
            \flutter_fixedfreq, flutter_fixedfreq,
            \flutter_variationfreq, flutter_variationfreq,
          ], 
  	      target: voiceGroup).onFree({ 
            // ("free").postln;
            voices.remove(newVoice); 
          })
        );
        voices.addFirst(newVoice);
      });
    });
		
		
		
    this.addCommand("set_numSegs", "f", { arg msg;
    	num_env_segments = msg[1];
    });
    
    this.addCommand("set_env_levels", "ffffffffffffffffffff", { arg msg;
      env_levels = Array.new(num_env_segments);
      for (0, num_env_segments-1, { arg i;
        var val = msg[i+1];
        env_levels.insert(i,val);
      }); 
    });
    
    this.addCommand("set_env_times", "ffffffffffffffffffff", { arg msg;
      env_times = Array.new(num_env_segments);
      for (0, num_env_segments-1, { arg i; 
        var val = msg[i+1];
        env_times.insert(i,val);
      }); 
    });
    
    this.addCommand("set_env_curves", "ffffffffffffffffffff", { arg msg;
      env_curves = Array.new(num_env_segments);
      for (0, num_env_segments-1, { arg i;
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
      effects.set(\effect_pitchshift, msg[1]);

    });

    this.addCommand("pitchshift_note1", "f", { arg msg;
      effects.set(\pitchshift_note1, msg[1]);
    });

    this.addCommand("pitchshift_note2", "f", { arg msg;
      effects.set(\pitchshift_note2, msg[1]);
    });

    this.addCommand("pitchshift_note3", "f", { arg msg;
      effects.set(\pitchshift_note3, msg[1]);
    });

    this.addCommand("update_scale", "ffffffffffffffffffffffff", { arg msg;
      var notes = Array.new(scale_length);
      var scale;
      for (0, scale_length-1, { arg i;
        var val = msg[i+1];
        notes.insert(i,val);
      }); 
      (["update scale",notes]).postln;
      scale = Buffer.loadCollection(context.server, notes);
      effects.set(\scale, scale);
    });

    this.addCommand("quantize_pitchshift", "f", { arg msg;
      msg[1].postln;
      effects.set(\quantize, msg[1]);
    });

    this.addCommand("grain_size", "f", { arg msg;
      effects.set(\grain_size, msg[1]);
    });

    this.addCommand("time_dispersion", "f", { arg msg;
      effects.set(\time_dispersion, msg[1]);
    });

  }

  free {
    voiceGroup.free;
    effects.free;
    effectsBus.free;
    controlBus.free;
	  //replyFunc.free;
    ("free flora objects").postln;
  }
}

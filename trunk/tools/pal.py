from math import *

def pal_coeffs(chord):
    U=[-0.147,-0.288,0.436]
    V=[0.615,-0.515,-0.1]
    
    print "\nU+V coefficients at R,G,B for %d phase angles (alpha-5/8):" % chord

    for c in iter(map(lambda a:map(sum, zip(map(lambda x:x*cos(a),V),map(lambda x:x*sin(a),U))),  map(lambda x:(x-5/(2.0*chord))*2*pi/chord,range(chord)))):
        print "%+2.4f %+2.4f %+2.4f   uvsum #(%+4d,%+4d,%+4d)" % tuple(c+map(lambda x:int(x*(2*0.714*256/3.3)*0.72),c))
	
    print "\nU-V coefficients at R,G,B for %d phase angles (alpha-3/8):" % chord
    for c in iter(map(lambda a:map(sum, zip(map(lambda x:-x*cos(a),V),map(lambda x:x*sin(a),U))),  map(lambda x:(x-3/(2.0*chord))*2*pi/chord,range(chord)))):
        print "%+2.4f %+2.4f %+2.4f   uvsum #(%+4d,%+4d,%+4d)" % tuple(c+map(lambda x:int(x*(2*0.714*256/3.3)*0.72),c))



def pal_calculate(clk,subcarrier,anglesteps,accu_bits):
    multiplier = 2**(accu_bits-3)
    print "\nPAL color everything finder"
    print "\nFor clk=%f MHz and target subcarrier frequency %f" % (clk, subcarrier)
    print "\nPhase accumulator increment = %d" % (round(multiplier*anglesteps/(clk/subcarrier)))
    pal_coeffs(anglesteps)

#map(lambda x:x*2*pi/chord,range(chord))


#pal_calculate(24,4.43361875,4,32)
pal_calculate(24,4.43361875,4,32)


Fmclk=300e6
Fsc=4433618.750
width=32

dPhase=4*Fsc/Fmclk*2**width

print "Fmclk=%f" % Fmclk
print "Fsc=%f" % Fsc
print "Phase accumulator width = %d" % width
print "delta phase=%d" % int(round(dPhase))
print "expected 4*Fsc=%f, Fsc=%f" % (dPhase*Fmclk/2**width, dPhase*Fmclk/2**width/4)

dPhase = dPhase - 60
print "expected 4*Fsc=%f, Fsc=%f" % (dPhase*Fmclk/2**width, dPhase*Fmclk/2**width/4)
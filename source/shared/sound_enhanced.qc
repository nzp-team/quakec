/*
	shared/sound_enhanced.qc

	mainly serves as a QC middleground for sound to adjust volume per 
    channel.

	Copyright (C) 2021-2024 NZ:P Team

	This program is free software; you can redistribute it and/or
	modify it under the terms of the GNU General Public License
	as published by the Free Software Foundation; either version 2
	of the License, or (at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

	See the GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program; if not, write to:

		Free Software Foundation, Inc.
		59 Temple Place - Suite 330
		Boston, MA  02111-1307, USA

*/

#define CHAN_MUSIC      1
#define CHAN_SFX        2

#ifdef FTE

void(string soundname, optional float channel, optional float volume) localsound_enhanced =
{
    if (!volume)
        volume = 1;

    switch(channel) {
        case 1: volume *= cvar("snd_channel1volume"); break;
        case 2: volume *= cvar("snd_channel2volume"); break;
        case 3: volume *= cvar("snd_channel3volume"); break;
        case 4: volume *= cvar("snd_channel4volume"); break;
        case 5: volume *= cvar("snd_channel5volume"); break;
        case 6: volume *= cvar("snd_channel6volume"); break;
        default: break;
    }

    localsound(soundname, channel, volume);
}

#endif // FTE

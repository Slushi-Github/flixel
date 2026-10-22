package flixel.graphics.tile;

import openfl.display.GraphicsShader;

class FlxGraphicsShader extends GraphicsShader
{
	@:glVertexHeader("
		attribute float alpha;
		attribute vec4 colorMultiplier;
		attribute vec4 colorOffset;
		uniform bool hasColorTransform;
	", true)
	@:glVertexBody("
		" +
		#if wiiu
		"openfl_Alphav = alpha;
		openfl_ColorOffsetv = colorOffset / 255.0;
		openfl_ColorMultiplierv = colorMultiplier;
		"
		#else
		"openfl_Alphav = openfl_Alpha * alpha;
		if (hasColorTransform)
		{
			if (openfl_HasColorTransform)
			{
				openfl_ColorOffsetv = (openfl_ColorOffsetv * colorMultiplier) + (colorOffset / 255.0);
				openfl_ColorMultiplierv *= colorMultiplier;
			}
			else
			{
				openfl_ColorOffsetv = colorOffset / 255.0;
				openfl_ColorMultiplierv = colorMultiplier;
			}
		}
		"
		#end
	, true)
	@:glFragmentHeader("
		" +
		#if wiiu
		"uniform bool hasTransform;
		uniform bool hasColorTransform;
		vec4 flixel_texture2D(sampler2D bitmap, vec2 coord)
		{
			vec4 color = texture2D(bitmap, coord);
			if (color.a == 0.0)
				return vec4(0.0, 0.0, 0.0, 0.0);
			
			float noColor = 1.0 - step(0.001, openfl_ColorMultiplierv.a);
			vec3 finalMult = mix(openfl_ColorMultiplierv.rgb, vec3(1.0), noColor);

			color = vec4(color.rgb / color.a, color.a);
			color = clamp(openfl_ColorOffsetv + (color * vec4(finalMult, 1.0)), 0.0, 1.0);
			
			return vec4(color.rgb * color.a, color.a);
		}
		"
		#else
		"uniform bool hasTransform;
		uniform bool hasColorTransform;
		vec4 flixel_texture2D(sampler2D bitmap, vec2 coord)
		{
			vec4 color = texture2D(bitmap, coord);
			if (!(hasTransform || openfl_HasColorTransform))
				return color;
			
			if (color.a == 0.0)
				return vec4(0.0, 0.0, 0.0, 0.0);
			
			if (openfl_HasColorTransform || hasColorTransform)
			{
				color = vec4 (color.rgb / color.a, color.a);
				vec4 mult = vec4 (openfl_ColorMultiplierv.rgb, 1.0);
				color = clamp (openfl_ColorOffsetv + (color * mult), 0.0, 1.0);
				
				if (color.a == 0.0)
					return vec4 (0.0, 0.0, 0.0, 0.0);
				
				return vec4 (color.rgb * color.a * openfl_Alphav, color.a * openfl_Alphav);
			}
			
			return color * openfl_Alphav;
		}
		"
		#end
	, true)
	@:glFragmentSource("
		#pragma header

		void main(void)
		{" +
		#if wiiu
		"
			gl_FragColor = flixel_texture2D(bitmap, openfl_TextureCoordv) * openfl_Alphav;
		" +
		#else
		"
			gl_FragColor = flixel_texture2D(bitmap, openfl_TextureCoordv);
		" +
		#end 
		"
		}
	", true)
	public function new()
	{
		super();
	}
}
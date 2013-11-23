package ;
import haxe.ds.StringMap.StringMap;
import haxe.Timer;
import js.Browser;
import js.html.KeyboardEvent;
import js.html.LinkElement;
import js.html.ScriptElement;

/**
 * ...
 * @author AS3Boyan
 */
 
 //This class is a global HIDE API for plugins
 //Using this API plugins can load JS and CSS scripts in specified order 
 //To use it in plugins you may need to add path to externs for this class, they are located at externs/plugins/hide
 
typedef PluginDependenciesData =
{
	var name:String;
	var plugins:Array<String>;
	var onLoaded:Void->Void;
	var callOnLoadWhenAtLeastOnePluginLoaded:Bool;
}
 
@:keepSub @:expose class HIDE
{	
	public static var plugins:Array<String> = new Array();
	public static var pathToPlugins:StringMap<String> = new StringMap();
	public static var inactivePlugins:Array<String> = ["boyan.ace.editor", "boyan.jquery.layout"];
	//public static var conflictingPlugins:Array<String> = [];
	
	public static var requestedPluginsData:Array<PluginDependenciesData> = new Array();
	
	//Loads JS scripts in specified order and calls onLoad function when last item of urls array was loaded
	public static function loadJS(name:String, urls:Array<String>, ?onLoad:Dynamic):Void
	{		
		if (name != null)
		{
			for (i in 0...urls.length)
			{
				urls[i] = js.Node.path.join(pathToPlugins.get(name), urls[i]);
			}
		}

		loadJSAsync(urls, onLoad);
	}
	
	//Asynchronously loads multiple CSS scripts
	public static function loadCSS(name:String, urls:Array<String>):Void
	{
		for (url in urls)
		{
			if (name != null)
			{
				url = js.Node.path.join(pathToPlugins.get(name), url);
			}
			
			var link:LinkElement = Browser.document.createLinkElement();
			link.href = url;
			link.type = "text/css";
			link.rel = "stylesheet";
			Browser.document.head.appendChild(link);
		}
	}
	
	public static function waitForDependentPluginsToBeLoaded(name:String, plugins:Array<String>, onLoaded:Void->Void, ?callOnLoadWhenAtLeastOnePluginLoaded:Bool = false):Void
	{	
		var data:PluginDependenciesData = { name:name, plugins:plugins, onLoaded:onLoaded, callOnLoadWhenAtLeastOnePluginLoaded:callOnLoadWhenAtLeastOnePluginLoaded };
		requestedPluginsData.push(data);
		checkRequiredPluginsData();
	}
	
	public static function notifyLoadingComplete(name:String):Void
	{
		plugins.push(name);
		checkRequiredPluginsData();
	}
	
	private static function checkRequiredPluginsData():Void
	{				
		if (requestedPluginsData.length > 0)
		{
			var pluginData:PluginDependenciesData;
		
			var j:Int = 0;
			while (j < requestedPluginsData.length)
			{
				pluginData = requestedPluginsData[j];
				
				var pluginsLoaded:Bool;
				
				if (pluginData.callOnLoadWhenAtLeastOnePluginLoaded == false)
				{
					pluginsLoaded = Lambda.foreach(pluginData.plugins, function (plugin:String):Bool
					{
						return Lambda.has(HIDE.plugins, plugin);
					}
					);
				}
				else 
				{
					pluginsLoaded = !Lambda.foreach(pluginData.plugins, function (plugin:String):Bool
					{
						return !Lambda.has(HIDE.plugins, plugin);
					}
					);
				}
				
				if (pluginsLoaded)
				{
					requestedPluginsData.splice(j, 1);
					pluginData.onLoaded();
				}
				else 
				{
					j++;
				}
			}
		
			if (Lambda.count(pathToPlugins) == plugins.length)
			{
				trace("all plugins loaded");
				
				var delta:Float = Date.now().getTime() - Main.currentTime;
				
				trace("Loading took: " + Std.string(delta) + " ms");
			}
		}
	}
	
	//Private function which loads JS scripts in strict order
	private static function loadJSAsync(urls:Array<String>, ?onLoad:Dynamic):Void
	{
		var script:ScriptElement = Browser.document.createScriptElement();
		script.src = urls.splice(0, 1)[0];
		script.onload = function (e)
		{
			trace(script.src + " loaded");
			
			if (urls.length > 0)
			{
				loadJSAsync(urls, onLoad);
			}
			else if (onLoad != null)
			{
				onLoad();
			}
		};
		
		Browser.document.head.appendChild(script);
	}
	
	public static function registerHotkey(hotkey:String, functionName:String):Void
	{
		
	}
	
	public static function registerHotkeyByKeyCode(code:Int, functionName:String):Void
	{
		Browser.window.addEventListener("keyup", function (e:KeyboardEvent)
		{
			if (e.keyCode == code)
			{
				//new JQuery().triggerHandler(functionName);
			}
			
			//trace(e.keyCode);
		}
		);
	}
	
}
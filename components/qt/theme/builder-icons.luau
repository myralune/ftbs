return function(key: string, filled: boolean, format: string, disabled: boolean)
	return not disabled and string.format(format,
		(`<font family="rbxasset://LuaPackages/Packages/_Index/BuilderIcons/BuilderIcons/BuilderIcons.json"{
			(filled and ' weight="Bold"' or '')
		}>{ key }</font>`)
	) or ""
end
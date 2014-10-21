#include "WkCocos/Save.h"

#include "WkCocos/Utils/log/logstream.h"

namespace WkCocos
{
	Save::Save(const std::string& saveName, Mode mode)
		: m_name(saveName)
		, m_onLoading(nullptr)
		, m_onSaving(nullptr)
		, m_saveInProgress(false)
		, m_loadInProgress(false)
	{
		m_saveModes[static_cast<int>(mode)] = 1;
	}
	
	Save::~Save()
	{}

	bool Save::requestLoadData(std::function<void()> loaded_cb, std::string key)
	{
		/*	m_localdata->loadPlayerData([=](std::string data)
		{
		rapidjson::Document doc;
		doc.Parse<0>(data.c_str());
		if (doc.HasParseError())
		{
		//if parse error (also empty string), we ignore existing data.
		doc.SetObject();
		}
		set_data_json(doc);
		});*/

		bool loaded = true;

		if (isMode(Mode::ONLINE)) //no encryption online
		{
			if (m_onlinedata&& !m_loadInProgress)
			{
				m_loadInProgress = true;
				m_onlinedata->load(m_user, m_name, [=](std::string data)
				{
					m_onLoading(data);
					CCLOG("user data loaded : %s", data.c_str());

					if (loaded_cb) loaded_cb();
					m_loadInProgress = false;
				});
			}
			else if ( !m_onlinedata)
			{
				LOG_WARNING << "Online load requested but no online manager!" << std::endl;
				loaded = false;
			}
			else if (m_loadInProgress)
			{
				LOG_WARNING << "Load already in progress. request ignored" << std::endl;
				loaded = false;
			}
		}

		if (isMode(Mode::OFFLINE))
		{
			if (m_localdata)
			{
				m_localdata->loadData(m_name, [=](std::string data){
					m_onLoading(data);

					if (loaded_cb) loaded_cb();
				}, key);
			}
			else
			{
				LOG_WARNING << "Offline load requested but no offline manager!" << std::endl;
				loaded = false;
			}
		}

		return loaded;
	}

	bool Save::requestSaveData(std::function<void()> saved_cb, std::string key)
	{
		/*	// create document
		rapidjson::Document doc;
		doc.SetObject();
		// must pass an allocator when the object may need to allocate memory
		rapidjson::Document::AllocatorType& allocator = doc.GetAllocator();

		get_data_json(doc, allocator);

		// Get the save string
		rapidjson::StringBuffer strbuf;
		rapidjson::Writer<rapidjson::StringBuffer> writer(strbuf);
		doc.Accept(writer);

		std::string save = std::string(strbuf.GetString());

		m_localdata->savePlayerData(save);*/
		bool saved = true;

		if (isMode(Mode::ONLINE)) //no encryption online
		{
			if (m_onlinedata && ! m_saveInProgress)
			{
				m_saveInProgress = true;
				m_onlinedata->save(m_user, m_name, m_onSaving(), [=](std::string data)
				{
					//CCLOG("user data saved : %s", data.c_str());
					if (saved_cb) saved_cb();
					m_saveInProgress = false;
				});
			}
			else if (! m_onlinedata)
			{
				LOG_WARNING << "Online save requested but no online manager!" << std::endl;
				saved = false;
			}
			else if (m_saveInProgress)
			{
				LOG_WARNING << "Save already in progress. request ignored." << std::endl;
				saved = false;
			}
		}

		if (isMode(Mode::OFFLINE))
		{
			if (m_localdata)
			{
				m_localdata->saveData(m_name, m_onSaving(), key);
				if (saved_cb) saved_cb();
			}
			else
			{
				LOG_WARNING << "Offline save requested but no offline manager!" << std::endl;
				saved = false;
			}
		}

		return saved;
		
	}

	bool Save::requestDeleteData(std::function<void()> delete_cb)
	{
		bool deleteSave = true;
		if (isMode(Mode::ONLINE))
		{
			//TODO
			LOG_WARNING << "Online save deletion not supported!" << std::endl;
		}
		if (isMode(Mode::OFFLINE))
		{
			if (m_localdata)
			{
				m_localdata->deleteData(m_name, [](std::string){});
			}
			else
			{
				LOG_WARNING << "Offline deletion requested but no offline manager!" << std::endl;
				deleteSave = false;
			}
		}
		return deleteSave;
	}

}// namespace WkCocos
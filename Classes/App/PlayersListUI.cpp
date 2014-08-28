#include "WkCocosApp/PlayersListUI.h"

#include "WkCocosApp/GameLogic.h"
#include "WkCocos/Utils/ToolBox.h"

#include "cocos2d.h"
#include "cocos/ui/CocosGUI.h"
#include "json/document.h"  

USING_NS_CC;

const std::string PlayersListUI::id = "players_list";

PlayersListUI::PlayersListUI()
	: Interface()
{
	//filepath is the id for the preload memory ( not used here )
	//m_filepath = id;

	//building UI hierarchy
	m_widget = ui::Layout::create();

	if (m_widget)
	{

		Size visibleSize = Director::getInstance()->getVisibleSize();
		m_widget->setContentSize(Size(visibleSize.width / 2, visibleSize.height / 2));
		m_widgetSize = m_widget->getContentSize();

		m_refreshButton = ui::Button::create("SkipNormal.png", "SkipSelected.png");
		m_refreshButton->addTouchEventListener(CC_CALLBACK_2(PlayersListUI::refreshCallback, this));
		m_refreshButton->setPosition(Vec2(m_widgetSize.width / 2, m_widgetSize.height / 3 * 2));
		m_widget->addChild(m_refreshButton);

		m_refreshLabel = ui::Text::create("reload players list", "Arial", 21);
		m_refreshLabel->setPosition(m_refreshButton->getPosition() + Vec2(0, m_refreshButton->getContentSize().height));
		m_widget->addChild(m_refreshLabel);
	
		m_enemyData = ui::Text::create("... GEMS and ... GOLD", "Arial", 21);
		m_enemyData->setPosition(Vec2(m_widgetSize.width / 2, m_widgetSize.height / 3));
		m_widget->addChild(m_enemyData);

		m_enemyLabel = ui::Text::create("player ... has", "Arial", 15);
		m_enemyLabel->setPosition(m_enemyData->getPosition() + Vec2(0, m_enemyData->getContentSize().height));
		m_widget->addChild(m_enemyLabel);

		m_widget->retain(); //we need to retain it in memory ( or cocos will drop it )
		widget_cache.insert(std::pair<std::string, ui::Widget*>(id, m_widget));

	}

	GameLogic::Instance().getPlayer().getOnlineDatamgr()->getEventManager()->subscribe<WkCocos::OnlineData::Events::PlayersList>(*this);
	GameLogic::Instance().getPlayer().getOnlineDatamgr()->getEventManager()->subscribe<WkCocos::OnlineData::Events::EnemyData>(*this);
	GameLogic::Instance().getPlayer().getAllUsers();
}

PlayersListUI::~PlayersListUI()
{
	std::map<std::string, cocos2d::ui::Text*>::iterator currentPTB = m_ptb.begin();
	for (; currentPTB != m_ptb.end(); ++currentPTB)
	{
		m_widget->removeChild(currentPTB->second);
		//delete currentPTB->second;
	}
	m_ptb.clear();
}

void PlayersListUI::receive(const WkCocos::OnlineData::Events::EnemyData &ed)
{
	cocos2d::Director::getInstance()->getScheduler()->performFunctionInCocosThread([=]()
	{
		m_enemyLabel->setText("player " + ed.enemy_name + " has");
		if (ed.enemy_docs)
			m_enemyData->setText(WkCocos::ToolBox::itoa(ed.enemy_gems) + " GEMS and " + WkCocos::ToolBox::itoa(ed.enemy_gold) + " GOLD");
		else
			m_enemyData->setText("no saved documents");
	});
}

void PlayersListUI::refreshCallback(Ref* widgetRef, ui::Widget::TouchEventType input)
{	
	if (input == ui::Widget::TouchEventType::ENDED)
	{	
		std::map<std::string, cocos2d::ui::Text*>::iterator currentPTB = m_ptb.begin();
		for (; currentPTB != m_ptb.end(); ++currentPTB)
		{
			m_widget->removeChild(currentPTB->second);
			//delete currentPTB->second;
		}
		m_ptb.clear();

		GameLogic::Instance().getPlayer().getAllUsers();
	}
}

void PlayersListUI::receive(const WkCocos::OnlineData::Events::PlayersList &pl)
{
	cocos2d::Director::getInstance()->getScheduler()->performFunctionInCocosThread([=]()
	{
		rapidjson::Document doc;
		doc.Parse<0>(pl.eventMessage.c_str());
		if (!doc.HasParseError())
		{
			if (doc.Size())
			{
				// with this value font size is no more than 15 and player name does not exceed half screen width
				int listSize = 42; 
				if (doc.Size() < listSize)
					listSize = doc.Size();

				for (rapidjson::SizeType i = 0; i < listSize; i++)
				{
					rapidjson::Value & userName = doc[i];

					std::string enemy_name = userName["userName"].GetString();

					cocos2d::ui::Text* playertextbutton = ui::Text::create("#" + WkCocos::ToolBox::itoa(i) + " " + enemy_name, "Arial", 15);
					playertextbutton->setPosition(Vec2(-m_widgetSize.width / 2, m_widgetSize.height * (1 - 2.0 / (listSize + 1) * (i + 1))));
					playertextbutton->setTouchEnabled(true);

					playertextbutton->addTouchEventListener
					(
						[=](Ref* widgetRef, ui::Widget::TouchEventType input)
						{
							if (input == ui::Widget::TouchEventType::ENDED)
								GameLogic::Instance().getPlayer().loadEnemy(enemy_name);
						}
					);

					m_ptb[enemy_name] = playertextbutton;

					m_widget->addChild(playertextbutton);
				}
			}
		}
	});
}
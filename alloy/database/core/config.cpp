/*
 * Tencent is pleased to support the open source community by making
 * WCDB available.
 *
 * Copyright (C) 2017 THL A29 Limited, a Tencent company.
 * All rights reserved.
 *
 * Licensed under the BSD 3-Clause License (the "License"); you may not use
 * this file except in compliance with the License. You may obtain a copy of
 * the License at
 *
 *       https://opensource.org/licenses/BSD-3-Clause
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include "config.hpp"

namespace aldb {

Configs::Configs() : _configs(new ConfigList) {}

Configs::Configs(std::initializer_list<const ConfigWrap> configs) : _configs(new ConfigList) {
    for (const auto &config : configs) {
        _configs->push_back(config);
    }
}

void Configs::set_config(const std::string &name, const Config &config, Configs::Order order) {
    std::shared_ptr<ConfigList> configs = _configs;
    std::shared_ptr<ConfigList> newConfigs(new ConfigList);
    bool inserted = false;
    for (const auto &wrap : *configs.get()) {
        if (!inserted && order < wrap._order) {
            newConfigs->push_back({name, config, order});
            inserted = true;
        } else if (name != wrap._name) {
            newConfigs->push_back(wrap);
        }
    }
    if (!inserted) {
        newConfigs->push_back({name, config, order});
    }
    _configs = newConfigs;
}

void Configs::set_config(const std::string &name, const Config &config) {
    std::shared_ptr<ConfigList> configs = _configs;
    std::shared_ptr<ConfigList> newConfigs(new ConfigList);
    bool inserted = false;
    for (const auto &wrap : *configs.get()) {
        if (name != wrap._name) {
            newConfigs->push_back(wrap);
        } else {
            newConfigs->push_back({name, config, wrap._order});
            inserted = true;
        }
    }
    if (!inserted) {
        newConfigs->push_back({name, config, INT_MAX});
    }
    _configs = newConfigs;
}

bool Configs::apply_configs(std::shared_ptr<Handle> &handle, ErrorPtr &error) {
    std::shared_ptr<ConfigList> configs = _configs;
    for (const auto &config : *configs.get()) {
        if (config._config && !config._config(handle, error)) {
            return false;
        }
    }
    return true;
}

bool operator==(const Configs &left, const Configs &right) { return left._configs == right._configs; }

bool operator!=(const Configs &left, const Configs &right) { return left._configs != right._configs; }

}  // namespace aldb
